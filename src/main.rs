#[macro_use]
extern crate rocket;

mod admin;

use admin::admin_routes;
use comrak::{markdown_to_html, Options};
use rocket::fs::relative;
use rocket::fs::FileServer;
use rocket::response::status::NotFound;
use rocket_db_pools::deadpool_postgres::{self};
use rocket_db_pools::{Connection, Database};
use rocket_dyn_templates::Template;
use serde::Serialize;

#[derive(Database)]
#[database("corybuecker")]
pub struct Db(deadpool_postgres::Pool);

#[derive(Serialize)]
struct Page {
    content: String,
}

#[get("/")]
fn home() -> Template {
    Template::render("home", {})
}

#[get("/<slug>")]
async fn page(db: Connection<Db>, slug: &str) -> Result<Template, NotFound<String>> {
    let result = db
        .query_one("select * from pages where slug = $1 limit 1", &[&slug])
        .await;

    match result {
        Ok(page) => {
            let content = page.get("content");
            let html = markdown_to_html(content, &Options::default());

            Ok(Template::render("page", Page { content: html }))
        }
        Err(_) => Err(NotFound("page not found".to_string())),
    }
}

#[post("/clicked")]
fn clicked() -> Template {
    Template::render("clicked", {})
}

#[launch]
fn rocket() -> _ {
    rocket::build()
        .attach(Db::init())
        .attach(Template::fairing())
        .mount("/assets", FileServer::from(relative!("static")))
        .mount("/admin", admin_routes())
        .mount("/", routes![home, page, clicked])
}
