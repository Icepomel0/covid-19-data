url <- "https://e.infogram.com/deaf4fd6-0ce9-4b82-97ae-11e34a045060"
page <- read_html(url)

script <- page %>%
    html_nodes("script") %>%
    html_text()
script <- script[which(str_detect(script, "window\\.infographicData"))]

header_string <- '"NUHI\\*","Border screening","Quarantine and random","deCODE Genetics"'

graph <- script %>%
    str_replace_all("null", "0") %>%
    str_extract_all(sprintf('%s[^A-Za-z]+', header_string)) %>%
    unlist
graph <- graph[which(!str_detect(graph, "%"))]

data <- graph %>%
    str_extract_all('\\[[0-9"\\.,]+\\]') %>%
    unlist %>%
    str_replace_all('["\\[\\]]', '') %>%
    str_split(",")

dates <- sapply(data, "[", 1) %>%
    paste0(".2020") %>%
    dmy()

df <- data.table(Date = dates, stringsAsFactors = FALSE)

categories <- header_string %>%
    str_extract_all("[A-Za-z ]+") %>%
    unlist

for (i in seq_along(categories)) {
    df[[categories[i]]] <- sapply(data, "[", i+1) %>% as.integer() %>% na_replace(0)
}

setDT(df)
df[, `Daily change in cumulative total` := NUHI + `deCODE Genetics` + `Quarantine and random`]

df[, Country := "Iceland"]
df[, Units := "tests performed"]
df[, `Source URL` := "https://www.covid.is/data"]
df[, `Source label` := "Government of Iceland"]
df[, Notes := NA_character_]
df[, `Testing type` := "PCR only"]
df[, c("NUHI", "deCODE Genetics", "Border screening", "Quarantine and random") := NULL]

old <- fread("automated_sheets/Iceland.csv")
old[, Date := ymd(Date)]
old <- old[Date < min(df$Date)]

full <- rbindlist(list(old, df), use.names = TRUE, fill = FALSE)
setorder(full, -Date)

fwrite(full, "automated_sheets/Iceland.csv")
