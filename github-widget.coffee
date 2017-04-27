###
# to minify:
java -jar /usr/local/closure-compiler/compiler.jar \
  --compilation_level SIMPLE_OPTIMIZATIONS \
  --js github-widget.js \
  --js_output_file github-widget.min.js
###

###* @preserve https://github.com/NateShoffner/github-widget
Modified work Copyright (c) 2016 Nate Shoffner
Original work Copyright (c) 2011 - 2012 George MacKerron
Released under the MIT licence: http://opensource.org/licenses/mit-license ###
makeWidget = (repos, div, opts) ->
  make cls: 'gw-clearer', prevSib: div
  for repo in repos
    make parent: div, cls: 'gw-repo-outer', kids: [
      make cls: 'gw-repo', kids: [
        make cls: 'gw-title', kids: [
          make tag: 'ul', cls: 'gw-stats', kids: [
            make tag: 'li', text: repo.watchers, cls: 'gw-watchers'
            make tag: 'li', text: repo.forks, cls: 'gw-forks']
          make tag: 'a', href: repo.html_url, text: repo.name, cls: 'gw-name']
        make cls: 'gw-lang', text: if repo.language? then repo.language else "Unknown Language"
        make cls: 'gw-repo-desc', text: if repo.description? then repo.description else "No description available"
        if opts.show_homepages and !!repo.homepage
          make cls: 'gw-homepage', kids: [
            make tag: 'a', href: repo.homepage, text: 'Homepage']]]

datetimeRegex = /^([\+-]?\d{4}(?!\d{2}\b))((-?)((0[1-9]|1[0-2])(\3([12]\d|0[1-9]|3[01]))?|W([0-4]\d|5[0-2])(-?[1-7])?|(00[1-9]|0[1-9]\d|[12]\d{2}|3([0-5]\d|6[1-6])))([T\s]((([01]\d|2[0-3])((:?)[0-5]\d)?|24\:?00)([\.,]\d+(?!:))?)?(\17[0-5]\d([\.,]\d+)?)?([zZ]|([\+-])([01]\d|2[0-3]):?([0-5]\d)?)?)?)?$/

@initialize_github_widgets = ->
  for div in (get tag: 'div', cls: 'github-widget')
    initialize_github_widget(div)

@initialize_github_widget = (div) ->
    do (div) ->  # close over correct div
      # remove existing repo nodes
      repo_nodes = div.getElementsByClassName('gw-repo-outer')
      while (repo_nodes[0])
          repo_nodes[0].parentNode.removeChild(repo_nodes[0]);
      users = (div.getAttribute 'data-user').split ','
      opts = div.getAttribute 'data-options'
      opts = if typeof opts is 'string' then JSON.parse(opts) else {}
      sortBy = opts.sortBy or 'watchers'
      limit = parseInt(opts.limit) or Infinity
      repos = []
      userCount = 0
      for user in users
        url = "https://api.github.com/users/#{user}/repos?callback=<cb>"
        jsonp url: url, success: (payload) ->
          if payload.data.length > 0
            first_repo = payload.data[0]
            userName = first_repo.owner.login
            siteRepoNames = ["#{userName}.github.com".toLowerCase(), "#{userName}.github.io".toLowerCase()]
            for repo in payload.data
              continue if (not opts.forks and repo.fork) or (not opts.siterepos and repo.name.toLowerCase() in siteRepoNames)
              repos.push repo
            userCount++
            if userCount is users.length and repos.length > 0
              if datetimeRegex.test(repos[0][sortBy])
                repos = repos.sort((a, b) -> new Date(b[sortBy])-new Date(a[sortBy]))
              else
                repos = repos.sort((a, b) -> b[sortBy] - a[sortBy])
              repos = repos[0..limit - 1]
              makeWidget repos, div, opts


# support functions

cls = (el, opts = {}) ->  # cut-down version: no manipulation support
  classHash = {}
  classes = el.className.match(cls.re)
  if classes?
    (classHash[c] = yes) for c in classes
  hasClasses = opts.has?.match(cls.re)
  if hasClasses?
    (return no unless classHash[c]) for c in hasClasses
    return yes
  null

cls.re = /\S+/g

get = (opts = {}) ->
  inside = opts.inside ? document
  tag = opts.tag ? '*'
  if opts.id?
    return inside.getElementById opts.id
  hasCls = opts.cls?
  if hasCls and tag is '*' and inside.getElementsByClassName?
    return inside.getElementsByClassName opts.cls
  els = inside.getElementsByTagName tag
  if hasCls then els = (el for el in els when cls el, has: opts.cls)
  if not opts.multi? and tag.toLowerCase() in get.uniqueTags then els[0] ? null else els

get.uniqueTags = 'html body frameset head title base'.split(' ')

text = (t) -> document.createTextNode '' + t

make = (opts = {}) ->  # opts: tag, parent, prevSib, text, cls, [attrib]
  t = document.createElement opts.tag ? 'div'
  for own k, v of opts
    switch k
      when 'tag' then continue
      when 'parent' then v.appendChild t
      when 'kids' then t.appendChild c for c in v when c?
      when 'prevSib' then v.parentNode.insertBefore t, v.nextSibling
      when 'text' then t.appendChild text v
      when 'cls' then t.className = v
      else t[k] = v
  t

jsonp = (opts) ->
  callbackName = opts.callback ? '_JSONPCallback_' + jsonp.callbackNum++
  url = opts.url.replace '<cb>', callbackName
  window[callbackName] = opts.success ? jsonp.noop
  make tag: 'script', src: url, parent: (get tag: 'head')

jsonp.callbackNum = 0
jsonp.noop = ->