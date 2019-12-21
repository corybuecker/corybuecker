import React from 'react'
import Link from 'next/link'

const Header = () => {
  return (
    <header>
      <nav>
        <Link href="/">
          <a className="home">Cory Buecker</a>
        </Link>
        <div>
          <a href="https://www.linkedin.com/in/corybuecker/">LinkedIn</a>
          <br />
          <a href="https://github.com/corybuecker">Github</a>
        </div>
      </nav>
    </header>
  )
}

export default Header
