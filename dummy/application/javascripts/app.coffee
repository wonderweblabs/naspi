define 'application/app', [
  'application/pkgs/test/test'
], (
  Test
) -> class App

  start: ->
    console.log 'YO'