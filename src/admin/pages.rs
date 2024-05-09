use super::User;
use crate::Db;
use rocket::form::Form;
use rocket::response::Redirect;
use rocket_db_pools::Connection;
use rocket_dyn_templates::{context, Template};

#[derive(FromForm)]
pub struct PostForm<'r> {
    slug: &'r str,
    title: &'r str,
    content: &'r str,
    publish: Option<bool>,
}

#[get("/pages")]
pub async fn pages(_u: User, db: Connection<Db>) -> Template {
    let raw_pages = db.query("select * from pages", &[]).await.unwrap();
    let mut pages = Vec::new();

    for page in raw_pages {
        let id: i32 = page.get("id");
        let title: String = page.get("title");
        let content: String = page.get("content");
        pages.push(context! {
            title: title,
            content: content,
            id: id,
        })
    }

    return Template::render("admin/pages", context! {pages: pages});
}

#[get("/pages/new")]
pub fn new(_u: User) -> Template {
    return Template::render("admin/new", context! {});
}

#[post("/pages", data = "<page>")]
pub async fn create(_u: User, db: Connection<Db>, page: Form<PostForm<'_>>) -> Redirect {
    db.execute(
        "insert into pages (slug, title, content, description, updated_at) values ($1, $2, $3, $3,now())",
        &[&page.slug, &page.title, &page.content],
    )
    .await
    .unwrap();
    return Redirect::to(uri!("/admin/pages"));
}

#[get("/pages/<id>/edit")]
pub async fn edit(_u: User, db: Connection<Db>, id: i32) -> Template {
    let page = db
        .query_one("select * from pages where id = $1", &[&id])
        .await
        .unwrap();

    let id: i32 = page.get("id");
    let title: String = page.get("title");
    let content: String = page.get("content");
    let slug: String = page.get("slug");

    return Template::render(
        "admin/edit",
        context! {id: id, title: title, content: content, slug: slug},
    );
}

#[post("/pages/<id>", data = "<page>")]
pub async fn patch(_u: User, db: Connection<Db>, id: i32, page: Form<PostForm<'_>>) -> Redirect {
    println!("{}", page.content);

    db.execute(
        "update pages set title = $1, content = $2, updated_at = now() where id = $3",
        &[&page.title, &page.content, &id],
    )
    .await
    .unwrap();

    match page.publish {
        None => {
            let _ = db
                .execute(
                    "update pages set published_at = null, updated_at = now() where id = $1",
                    &[&id],
                )
                .await;
        }
        Some(publish) => {
            let _ = db
                .execute(
                    "update pages set published_at = $1, updated_at = now() where id = $2",
                    &[&publish, &id],
                )
                .await;
        }
    }

    return Redirect::to(uri!("/admin/pages"));
}
