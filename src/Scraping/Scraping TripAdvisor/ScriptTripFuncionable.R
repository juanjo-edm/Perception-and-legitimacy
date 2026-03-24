library(RSelenium)

# Definir las variables
url <- "https://www.tripadvisor.com/ShowTopic-g294074-i3499-k14315810-Staying_safe_in_Bogota-Bogota.html#116880344"

# Función para rotar User-Agent
get_user_agent <- function() {
  user_agents <- c(
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.93 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:89.0) Gecko/20100101 Firefox/89.0",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0.3 Safari/605.1.15"
  )
  sample(user_agents, 1)
}


# Encender Selenium
rs_driver_object <- rsDriver(
  browser = "chrome",
  chromever = "106.0.5249.21",
  verbose = FALSE, # suprimir mensajes
  port = free_port() # puerto libre de netstat
)

# Crear un objeto cliente
remDr <- rs_driver_object$client

# Cambiar el User-Agent
user_agent <- get_user_agent()
remDr$executeScript(paste0('navigator.__defineGetter__("userAgent", function() { return "', user_agent, '"; });'))

# Añadir un delay para simular comportamiento humano
Sys.sleep(sample(3:10, 1))

# Navegar a un sitio web
remDr$navigate(url)

# Añadir otro delay
Sys.sleep(sample(3:10, 1))


# Now click all the elements with class "exapand review"  
remDr$findElements("xpath", ".//div[contains(@data-test-target, 'expand-review')]")[[1]]$clickElement()

# we idetify the title by class and we spacify the name of the class 

titles <- remDr$findElements(using = "class", "topTitleText")
length(titles)
titles_values <- lapply(titles, function(x) x$getElementText()) %>% unlist() # for each element in the list get the text element 
titles_values

# we idetify Username by class and we spacify the name of the class 
username <- remDr$findElements(using = "class", "username")
length(username)
head(username)
username_values <- lapply(username, function(x) x$getElementText()) %>% unlist() # for each element in the list get the text element 
username_values

# we idetify comments by class and we spacify the name of the class 
comments <- remDr$findElements(using = "class", "postBody")
length(comments)
Comments_values <- lapply(comments, function(x) x$getElementText()) %>% unlist() # for each element in the list get the text element 
Comments_values

#Antes de hacer cambio de pagina simular comportamiento humano


# Cambiar el User-Agent
user_agent <- get_user_agent()
remDr$executeScript(paste0('navigator.__defineGetter__("userAgent", function() { return "', user_agent, '"; });'))

# Añadir un delay para simular comportamiento humano
Sys.sleep(sample(3:10, 1))



#find element  forn next pages 
Siguiente_objetc <- remDr$findElement(using = "link text", "»")
Siguiente_objetc$getElementAttribute("href")
Siguiente_objetc$clickElement()

# Limpiar====
remDr$close()
rD[["server"]]$stop()

#====================
#terminate seelenium server
system("taskkill /im java.exe /f")
