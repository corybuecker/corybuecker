module.exports = {
  content: [
    './js/**/*.js',
    '../templates/**/*'
  ],
  theme: {
    extend: {},
  },
  plugins: [
    require('@tailwindcss/forms')
  ]
}
