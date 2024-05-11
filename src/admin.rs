mod authentication;
mod pages;
use crate::Db;
use rocket::request::Outcome;
use rocket::{request::FromRequest, Request, Route};
use rocket_db_pools::Connection;

struct User {
    email: String,
}

#[derive(Debug)]
enum AuthenticationError {
    NoEmail,
}

#[rocket::async_trait]
impl<'a> FromRequest<'a> for User {
    type Error = AuthenticationError;

    async fn from_request(req: &'a Request<'_>) -> Outcome<Self, Self::Error> {
        let database = req.guard::<Connection<Db>>().await.unwrap();

        let cookies = req.cookies();
        let email_cookie = cookies.get_private("email");

        match email_cookie {
            Some(email_cookie) => {
                let email = email_cookie.value().to_string();
                let user = database
                    .query_one("select 1 from users where email = $1 limit 1", &[&email])
                    .await;

                match user {
                    Ok(_) => return Outcome::Success(User { email: email }),
                    Err(_) => {
                        return Outcome::Error((
                            rocket::http::Status::Unauthorized,
                            AuthenticationError::NoEmail,
                        ))
                    }
                }
            }
            None => {
                return Outcome::Error((
                    rocket::http::Status::Unauthorized,
                    AuthenticationError::NoEmail,
                ))
            }
        }
    }
}

pub fn admin_routes() -> Vec<Route> {
    return routes![
        authentication::login,
        authentication::callback,
        pages::pages,
        pages::new,
        pages::create,
        pages::edit,
        pages::patch
    ];
}
