use super::User;
use crate::Db;
use rocket_db_pools::Connection;
use rocket_dyn_templates::{context, Template};
use serde::Serialize;

#[derive(Serialize)]
struct Page {
    title: String,
    content: String,
}

#[get("/pages")]
pub async fn pages(_u: User, db: Connection<Db>) -> Template {
    let raw_pages = db.query("select * from pages", &[]).await.unwrap();
    let mut pages = Vec::new();

    for p in raw_pages {
        pages.push(Page {
            title: p.get("title"),
            content: p.get("content"),
        })
    }

    return Template::render("admin/pages", context! {pages: pages});
}
