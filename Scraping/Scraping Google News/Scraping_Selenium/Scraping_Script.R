# === 0. LIBRERÍAS ===
library(RSelenium)
library(netstat)
library(tidyverse)
library(glue)
library(lubridate)
library(stringr)
library(rvest)   # <- para leer el cuerpo de la noticia

# === 1. CONFIGURACIÓN ===

# Vector con las localidades que compartiste
localidades <- c(
  "ANTONIO NARIÑO",
  "BARRIOS UNIDOS",
  "BOSA",
  "CANDELARIA",
  "CHAPINERO",
  "CIUDAD BOLÍVAR",
  "ENGATIVÁ",
  "FONTIBÓN",
  "KENNEDY",
  "LOS MÁRTIRES",
  "PUENTE ARANDA",
  "RAFAEL URIBE URIBE",
  "SAN CRISTÓBAL",
  "SANTA FE",
  "SUBA",
  "TEUSAQUILLO",
  "TUNJUELITO",
  "USAQUÉN",
  "USME",
  "SUMAPAZ" # incluyo Sumapaz para luego excluirlo
)

# Excluir Sumapaz explícitamente
localidades <- localidades[localidades != "SUMAPAZ"]

# Crear las consultas
consultas <- paste("seguridad hurtos Bogotá", localidades)

consultas


# Establecemos fechas
fecha_inicio <- as.Date("2024-01-01")
# fecha_fin    <- as.Date("2024-03-01")
fecha_fin    <- Sys.Date()

hl <- "es-419"
gl <- "CO"
max_paginas_por_mes <- 30

espera_min <- 2
espera_max <- 4

get_user_agent <- function() {
  sample(c(
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0.3 Safari/605.1.15",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.116 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:89.0) Gecko/20100101 Firefox/89.0"
  ), 1)
}

formatear_mmddyyyy <- function(fecha) format(as.Date(fecha), "%m/%d/%Y")

build_google_news_url <- function(query, dmin, dmax, start = 0, hl = "es-419", gl = "CO") {
  q <- utils::URLencode(query, reserved = TRUE)
  cd_min <- formatear_mmddyyyy(dmin)
  cd_max <- formatear_mmddyyyy(dmax)
  glue(
    "https://www.google.com/search?q={q}",
    "&tbm=nws&hl={hl}&gl={gl}",
    "&tbs=cdr:1,cd_min:{cd_min},cd_max:{cd_max}",
    "&start={start}"
  )
}

# === 2. INICIAR SELENIUM ===

rD <- rsDriver(
  browser = "chrome",
  chromever = NULL,    # ahora NULL detecta la última versión instalada
  port = free_port(),
  verbose = FALSE,
  check = FALSE,
  phantomver = NULL    # 👈 evita el error de phantomjs
)

remDr <- rD$client

# === 3. FUNCIONES DE SCRAPING ===

aceptar_consentimiento <- function() {
  try({
    Sys.sleep(runif(1, espera_min, espera_max))
    btns <- remDr$findElements("css selector",
                               "button#L2AGLb, button[aria-label*='Acepto'], button[aria-label*='Estoy de acuerdo']")
    if (length(btns) > 0) {
      btns[[1]]$clickElement()
      Sys.sleep(runif(1, 1.0, 2.0))
    }
  }, silent = TRUE)
}

get_first_text <- function(node, css_vec) {
  for (css in css_vec) {
    kids <- try(node$findChildElements("css selector", css), silent = TRUE)
    if (!inherits(kids, "try-error") && length(kids) > 0) {
      val <- try(kids[[1]]$getElementText()[[1]], silent = TRUE)
      if (!inherits(val, "try-error") && !is.null(val) && nchar(val) > 0) return(val)
    }
  }
  NA_character_
}

get_first_attr <- function(node, css_vec, attr) {
  for (css in css_vec) {
    kids <- try(node$findChildElements("css selector", css), silent = TRUE)
    if (!inherits(kids, "try-error") && length(kids) > 0) {
      val <- try(kids[[1]]$getElementAttribute(attr)[[1]], silent = TRUE)
      if (!inherits(val, "try-error") && !is.null(val) && nchar(val) > 0) return(val)
    }
  }
  NA_character_
}

extraer_pagina <- function(consulta, dmin, dmax, pagina_idx) {
  Sys.sleep(sample(espera_min:espera_max, 1))
  contenedores <- remDr$findElements("css selector",
                                     "div.SoaBEf, div.dbsr, div.Gx5Zad.fP1Qef.xpd.EtOod.pkphOe")
  if (length(contenedores) == 0) return(tibble())
  
  rows <- lapply(contenedores, function(b) {
    titulo <- get_first_text(b, c("div[role='heading']", "h3", "div.JheGif.nDgy9d"))
    enlace <- get_first_attr(b, c("a.VDXfz", "a"), "href")
    fuente <- get_first_text(b, c("div.SVJrMe a", "div.CEMjEf span", "span.xQ82C.e8fRJf", "span.wmnc8c"))
    fecha_texto <- get_first_text(b, c("time", "span.WG9SHc span", "span.OSrXXb"))
    fecha_iso   <- get_first_attr(b, c("time"), "datetime")
    resumen     <- get_first_text(b, c("div.GI74Re", "div.Y3v8qd", "div.gG0TJc"))
    
    tibble(
      consulta = consulta,
      titulo = titulo,
      resumen = resumen,
      fuente = fuente,
      fecha_texto = fecha_texto,
      fecha_iso = fecha_iso,
      enlace = enlace,
      fecha_chunk_desde = as.Date(dmin),
      fecha_chunk_hasta = as.Date(dmax),
      pagina = pagina_idx
    )
  })
  
  bind_rows(rows) %>% filter(!is.na(titulo) | !is.na(enlace)) %>% distinct()
}

# === NUEVO: función para cuerpo completo ===
extraer_articulo <- function(url) {
  tryCatch({
    pagina <- read_html(url)
    cuerpo <- pagina %>%
      html_elements("p") %>%
      html_text(trim = TRUE) %>%
      paste(collapse = " ")
    tibble(enlace = url, cuerpo = cuerpo)
  }, error = function(e) {
    tibble(enlace = url, cuerpo = NA_character_)
  })
}

# === 4. LOOP PRINCIPAL ===

inicios_mes <- seq(from = floor_date(fecha_inicio, "month"),
                   to   = floor_date(fecha_fin, "month"),
                   by   = "1 month")
fines_mes <- pmin(inicios_mes %m+% months(1) - days(1), fecha_fin)

datos <- list()

for (consulta in consultas) {
  url_inicial <- build_google_news_url(consulta, inicios_mes[1], fines_mes[1], start = 0, hl = hl, gl = gl)
  remDr$navigate(url_inicial)
  aceptar_consentimiento()
  
  for (i_mes in seq_along(inicios_mes)) {
    dmin <- inicios_mes[i_mes]; dmax <- fines_mes[i_mes]
    start <- 0L
    for (i_pag in 1:max_paginas_por_mes) {
      message(glue("Scrapeando '{consulta}' | {dmin}–{dmax} | página {i_pag} (start={start})..."))
      try({
        user_agent <- get_user_agent()
        remDr$executeScript(paste0(
          'navigator.__defineGetter__("userAgent", function() { return "', user_agent, '"; });'
        ))
      }, silent = TRUE)
      
      url <- build_google_news_url(consulta, dmin, dmax, start = start, hl = hl, gl = gl)
      remDr$navigate(url); aceptar_consentimiento()
      
      page_html <- try(remDr$getPageSource()[[1]], silent = TRUE)
      if (!inherits(page_html, "try-error")) {
        if (str_detect(page_html, regex("unusual traffic|detected unusual traffic|recaptcha", TRUE))) {
          warning("Posible bloqueo/CAPTCHA detectado; deteniendo este rango.")
          break
        }
      }
      
      df <- extraer_pagina(consulta, dmin, dmax, pagina_idx = i_pag)
      if (nrow(df) == 0) break else {
        datos[[length(datos) + 1]] <- df
        start <- start + 10L
        Sys.sleep(runif(1, espera_min + 0.5, espera_max + 1.0))
      }
    }
  }
}

# === 5. CERRAR Y GUARDAR ===
remDr$close(); rD$server$stop()

tabla_noticias <- bind_rows(datos) %>% distinct(consulta, titulo, enlace, .keep_all = TRUE)

# === 6. EXTRAER CUERPO DE CADA NOTICIA ===
detalles <- purrr::map_dfr(tabla_noticias$enlace, extraer_articulo)

tabla_completa <- tabla_noticias %>% left_join(detalles, by = "enlace")
