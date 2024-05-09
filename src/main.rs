#[macro_use]
extern crate rocket;

mod admin;

use comrak::{markdown_to_html, Options};
use rocket::fs::relative;
use rocket::fs::FileServer;
use rocket::response::status::NotFound;
use rocket_db_pools::deadpool_postgres::{self};
use rocket_db_pools::{Connection, Database};
use rocket_dyn_templates::context;
use rocket_dyn_templates::Template;

#[derive(Database)]
#[database("corybuecker")]
pub struct Db(deadpool_postgres::Pool);

#[get("/")]
async fn home(db: Connection<Db>) -> Template {
    let current_page_raw = db
        .query_one(
            "select slug, title, content from pages order by published_at desc limit 1",
            &[],
        )
        .await
        .unwrap();

    let raw_pages = db
        .query(
            "select slug, title from pages where slug <> $1 order by published_at desc",
            &[&current_page_raw.get::<&str, String>("slug")],
        )
        .await
        .unwrap();

    let mut pages = Vec::new();

    let content: &str = current_page_raw.get("content");
    let html = markdown_to_html(content, &Options::default());

    let title: String = current_page_raw.get("title");
    let slug: String = current_page_raw.get("slug");

    let current_page = context! {
        title: title,
        slug: slug,
        content: html
    };

    for page in raw_pages {
        let slug: String = page.get("slug");
        let title: String = page.get("title");

        pages.push(context! {
            slug: slug,
            title: title,
        })
    }

    Template::render("home", context! {pages: pages, current_page: current_page})
}

#[get("/post/<slug>")]
async fn page(db: Connection<Db>, slug: &str) -> Result<Template, NotFound<String>> {
    let result = db
        .query_one("select * from pages where slug = $1 limit 1", &[&slug])
        .await;

    match result {
        Ok(page) => {
            let content = page.get("content");
            let html = markdown_to_html(content, &Options::default());
            let title: String = page.get("title");

            Ok(Template::render(
                "page",
                context! { content: html, title: title },
            ))
        }
        Err(_) => Err(NotFound("page not found".to_string())),
    }
}

#[launch]
fn rocket() -> _ {
    rocket::build()
        .attach(Db::init())
        .attach(Template::fairing())
        .mount("/assets", FileServer::from(relative!("static")))
        .mount("/admin", admin::admin_routes())
        .mount("/", routes![home, page])
}
