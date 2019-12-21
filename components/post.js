import Markdown from 'react-markdown'
import React from 'react'
import PropTypes from 'prop-types'
import Link from 'next/link'
const Post = ({ title, published, body, path }) => {
  return (
    <article>
      <h1>{title}</h1>
      <p>
        <time dateTime={published}>
          {new Date(published).toLocaleDateString()}
        </time>
      </p>

      <div>
        <Markdown source={body}></Markdown>
      </div>
    </article>
  )
}
Post.propTypes = {
  title: PropTypes.string.isRequired,
  published: PropTypes.string.isRequired,
  body: PropTypes.string.isRequired,
  path: PropTypes.string.isRequired
}
export default Post
