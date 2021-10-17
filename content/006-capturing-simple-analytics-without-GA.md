---
title: How to capture simple blog analytics without Google Analytics
published: 2020-01-05T17:27:46Z
revised: 2021-02-07 18:24:48
draft: false
preview: As part of building my blog, I wanted to capture some analytics with a simple, privacy-focused approach.
description: Capture simple analytics for a blog with a privacy-oriented approach.
slug: capture-simple-analytics-without-google-analytics
---

As part of this building my blog, I wanted to capture some analytics with a simple, privacy-focused approach. Normally, I would reach for Google Analytics or [Fathom](https://usefathom.com/), but it is a simple problem to solve with Cloud Run and [Cloud Firestore](https://firebase.google.com/docs/firestore). I have created [Exlytics](https://github.com/corybuecker/exlytics) as an example of my approach in under 100 lines of Elixir code.

## Cookies

In Exlytics or this website, I don't use cookies at all.

Google Analytics relies on a cookie to remember the steps a particular visitor follows around a website. While [this is now a first-party cookie](https://clearcode.cc/blog/difference-between-first-party-third-party-cookies/), I don't see the need to use cookies for a simple blog. I'm not interested in distinct user analytics for a small site.

Safari is a leader in web tracking privacy with their [Intelligent Tracking Prevention (ITP) technology](https://webkit.org/blog/9521/intelligent-tracking-prevention-2-3/). If I do use this technique again for a different site and want to know a user's actions on my site only, I can add a first-party cookie at that time. This should be safe with ITP as long as Exlytics is hosted on a subdomain (shared eTLD+1) of that site.

## Personally identifiable information (PII)

Exlytics uses the request headers, combined with the query string, to record an analytics request. Unfortuntely, that includes more information than I really need to capture. The GDPR, under Recital 30, indicates that [online identifiers may include IP addresses](https://gdpr-info.eu/recitals/no-30/).

In Exlytics, I have limited the saved headers to those in [an approved list](https://github.com/corybuecker/exlytics/blob/main/lib/router.ex#L6). Initially, this list includes: user agent, referer, host and origin. Referer can be controversial since it tells me where a visitor came from. However, I have added a [referer-policy header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Referrer-Policy) to this website to instruct the browser to only send the origin of the referer. 

## Self-hosted

Hosting my own analytics is inexpensive with Cloud Run and Firestore. In fact, it is free in almost all cases.

The tradeoff is that I am responsible for aggregating and visualizing that data. I'll write a follow-up post with some of the techniques and tools I have been using to visualize the data.

## Exlytics (backend)

The [Exlytics](https://github.com/corybuecker/exlytics) service accepts both GET and POST requests to the root path. It uses the Google-maintained [Firestore API library](https://github.com/googleapis/elixir-google-api/tree/master/clients/firestore) to build and save the events. The most important transformation converts approved request headers into [Firestore documents](https://github.com/googleapis/elixir-google-api/blob/master/clients/firestore/lib/google_api/firestore/v1/model/document.ex).

```elixir
@allowed_headers ["host", "origin", "referer", "user-agent"]

defp document(%Plug.Conn{} = conn) do
  %Document{
    fields: req_headers_map(conn)
  }
end

defp req_headers_map(%Plug.Conn{} = conn) do
  conn.req_headers |> filter_by_allowed() |> to_google_fields()
end

defp filter_by_allowed(headers) do
  headers |> Enum.filter(fn {header, _value} -> Enum.member?(@allowed_headers, header) end)
end

defp to_google_fields(values) when is_list(values) or is_map(values) do
  Enum.reduce(values, %{}, fn {key, value}, acc ->
    acc |> Map.put(key, %Value{stringValue: value})
  end)
end
```

Exlytics also stores any query string parameters as individual values in the Firestore document.

```elixir
defp document(%Plug.Conn{} = conn) do
  %Document{
    fields:
      req_headers_map(conn)
      |> Map.merge(query_params_map(conn))
  }
end

defp req_headers_map(%Plug.Conn{} = conn) do
  conn.req_headers |> filter_by_allowed() |> to_google_fields()
end

defp filter_by_allowed(headers) do
  headers |> Enum.filter(fn {header, _value} -> Enum.member?(@allowed_headers, header) end)
end

defp query_params_map(%Plug.Conn{} = conn) do
  conn = conn |> fetch_query_params()

  conn.query_params |> to_google_fields()
end

defp to_google_fields(values) when is_list(values) or is_map(values) do
  Enum.reduce(values, %{}, fn {key, value}, acc ->
    acc |> Map.put(key, %Value{stringValue: value})
  end)
end
```

## Sending events to Exlytics

Any request sent to Exlytics will be stored in Firestore. The simplest approach to save page views is by adding this Javascript snippet somewhere on each page.

```javascript
const recordPageview = () => {
  const analyticsUrl = new URL('https://exlytics.corybuecker.com')
  const pageUrl = new URL(window.location.toString())

  analyticsUrl.search = `page=${pageUrl.pathname}`

  return navigator.sendBeacon(analyticsUrl.toString())
}

recordPageview()
```

Note the use of [`sendBeacon`](https://developer.mozilla.org/en-US/docs/Web/API/Navigator/sendBeacon); the [Fetch API](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API) would work well here, but I have another reason to use the [Navigator API](https://developer.mozilla.org/en-US/docs/Web/API/Navigator). Using `sendBeacon` captures _outgoing_ link clicks without blocking the load of the third-party webpage.

```javascript
handleTrackedAnchorClick(event) {
  const target = event.currentTarget
  const analyticsUrl = new URL('https://exlytics.corybuecker.com')

  analyticsUrl.search = `click_link=${target.href}`

  navigator.sendBeacon(analyticsUrl.toString())
}
```
