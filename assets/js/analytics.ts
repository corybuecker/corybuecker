const EXLYTICS_URL = "https://exlytics.corybuecker.com"
const EXLYTICS_ACCOUNT = "c1c35a41-a439-404f-95a6-cdbfd5323b28"

const recordPageview = (): undefined => {
  const analyticsUrl = new URL(EXLYTICS_URL)
  const pageUrl = new URL(window.location.toString())
  const data = {
    account_id: EXLYTICS_ACCOUNT,
    page: pageUrl.pathname
  }

  navigator.sendBeacon(analyticsUrl.toString(), JSON.stringify(data))
  return
}

recordPageview()

const formatTimeElement = (element: HTMLTimeElement): void => {
  const timeString = element.dateTime
  element.innerText = new Date(timeString).toLocaleDateString()
}

const trackAnchor = (element: HTMLAnchorElement): undefined => {
  element.addEventListener('click', _event => {
    const analyticsUrl = new URL(EXLYTICS_URL)
    const data = {
      account_id: EXLYTICS_ACCOUNT,
      click_link: element.href
    }

    navigator.sendBeacon(analyticsUrl.toString(), JSON.stringify(data))
    return
  })

  return
}

const timeElements = document.getElementsByTagName('time')
Array.from(timeElements).forEach(formatTimeElement)

const anchorElements = document.getElementsByTagName('a')
Array.from(anchorElements).forEach(trackAnchor)
