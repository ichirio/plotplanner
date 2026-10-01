# The coverage tables of iter00, as Markdown (for the iteration record).
a <- readRDS("data-raw/brushup/ard_coverage.rds")
t <- readRDS("data-raw/brushup/table_coverage.rds")
esc <- function(x) gsub("|", "\\|", gsub("\n", " ", x), fixed = TRUE)
cat("| id | 分類 | 関数 | 書き方 | 一致 | 値の数 | メモ |\n|---|---|---|---|---|---|---|\n")
for (i in seq_len(nrow(a))) {
  cat(sprintf("| %s | %s | `%s` | %s | %s | %s | %s |\n", a$id[i], a$group[i],
              a$fun[i], a$status[i], if (isTRUE(a$same[i])) "OK" else "NG",
              a$n[i], esc(a$note[i])))
}
cat("\n\n| case | 同じページ | Spec にできなかったもの |\n|---|---|---|\n")
for (i in seq_len(nrow(t))) {
  cat(sprintf("| %s | %s | %s |\n", t$case[i],
              if (isTRUE(t$same_pages[i])) "OK" else "NG",
              esc(t$not_converted[i])))
}
