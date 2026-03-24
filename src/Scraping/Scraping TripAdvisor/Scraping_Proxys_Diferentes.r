library(RSelenium)
library(netstat)
library(tidyverse)
library(glue)

# === 1. CONFIGURACIÓN ===
url_base <- "https://www.tripadvisor.com/ShowTopic-g294074-i3499-k14315810-Staying_safe_in_Bogota-Bogota.html"
# Buscar puerto que acepte google y https: https://free-proxy-list.net/en/
proxy_manual <- "5.78.130.46:12016"
n_paginas <- 2  # Puedes aumentarlo segun el tamano de la paguina 


get_user_agent <- function() {
  sample(c(
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0.3 Safari/605.1.15",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.116 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:89.0) Gecko/20100101 Firefox/89.0"
  ), 1)
}

# === 2. INICIAR SELENIUM CON PROXY ===
chrome_opts <- list(
  chromeOptions = list(
    args = list(
      paste0("--proxy-server=http://", proxy_manual),
      "--disable-blink-features=AutomationControlled"
    )
  )
)

rD <- rsDriver(
  browser = "chrome",
  chromever = NULL,
  port = free_port(),
  verbose = FALSE,
  phantomver = NULL,
  extraCapabilities = chrome_opts
)
remDr <- rD$client

# === 3. FUNCIONES DE SCRAPING ===

extraer_pagina <- function() {
  Sys.sleep(sample(2:4, 1))  # Pausa aleatoria
  
  # Expandir reseñas si hay botón
  expand_buttons <- remDr$findElements("xpath", ".//div[contains(@data-test-target, 'expand-review')]")
  lapply(expand_buttons, function(x) try(x$clickElement(), silent = TRUE))
  
  # Extraer texto
  titles_txt <- remDr$findElements("class name", "topTitleText") %>%
    lapply(\(x) x$getElementText()) %>% unlist()
  
  users_txt <- remDr$findElements("class name", "username") %>%
    lapply(\(x) x$getElementText()) %>% unlist()
  
  comments_txt <- remDr$findElements("class name", "postBody") %>%
    lapply(\(x) x$getElementText()) %>% unlist()
  
  # Igualar longitudes
  max_len <- max(length(titles_txt), length(users_txt), length(comments_txt))
  fix_len <- function(x) { length(x) <- max_len; x }
  
  tibble(
    titulo = fix_len(titles_txt),
    usuario = fix_len(users_txt),
    comentario = fix_len(comments_txt)
  )
}

# === 4. LOOP PRINCIPAL ===

datos <- list()
remDr$navigate(url_base)

for (i in 1:n_paginas) {
  message(glue("Scrapeando página {i}..."))
  
  # Cambiar user-agent (decorativo)
  try({
    user_agent <- get_user_agent()
    remDr$executeScript(paste0(
      'navigator.__defineGetter__("userAgent", function() { return "', user_agent, '"; });'
    ))
  }, silent = TRUE)
  
  datos[[i]] <- extraer_pagina()
  
  # Ir a siguiente página
  if (i < n_paginas) {
    try({
      next_btn <- remDr$findElement("link text", "»")
      next_btn$clickElement()
      Sys.sleep(sample(3:6, 1))
    }, silent = TRUE)
  }
}

# === 5. CERRAR Y GUARDAR ===

remDr$close()
rD$server$stop()

resultados <- bind_rows(datos)
