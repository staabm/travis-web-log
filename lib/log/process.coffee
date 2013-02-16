Log.Part = (log, num, string) ->
  @log = log
  @num = num
  @lines = for line, ix in string.replace(/\r\n/gm, "\n").split(/^/m)
    new Log.Line(@, ix, line)
  @
$.extend Log.Part.prototype,
  insert: ->
    new Log.Context(@log, @).insert()
  head: ->
    head = []
    line = @lines[0]
    while (line = line?.prev()) && !line.isNewline()
      head.unshift(line)
    head
  tail: ->
    tail = []
    line = @lines[@lines.length - 1]
    while line = line?.next()
      tail.push(line)
      break if line?.isNewline()
    tail
  prev: ->
    num  = @num
    prev = @log.parts[num -= 1] until prev || num < 0
    prev
  next: ->
    num  = @num
    next = @log.parts[num += 1] until next || num >= @log.parts.length
    next

Log.Line = (part, num, string) ->
  @part = part
  @num  = num
  @id   = "#{part.num}-#{num}"
  @string = string
  @
$.extend Log.Line.prototype,
  prev: ->
    line = @part.lines[@num - 1]
    line || @part.prev()?.lines.slice(-1)[0]
  next: ->
    line = @part.lines[@num + 1]
    line || @part.next()?.lines[0]
  isNewline: ->
    @string[@string.length - 1] == "\n"
  clone: ->
    new Log.Line(@part, @num, @string)

Log.Context = (log, part) ->
  @log   = log
  @part  = part
  @head  = part.head()
  @tail  = part.tail()
  @lines = @join(@head.concat(part.lines).concat(@tail))
  @
$.extend Log.Context.prototype,
  insert: ->
    ids = @head.concat(@tail).map (line) -> line.id
    @log.trigger('remove', ids) unless ids.length == 0
    @log.trigger('insert', @after(), @nodes())
  nodes: ->
    @lines.map (line) =>
      string = line.string
      if fold = @defold(string)
        $.extend(fold, id: line.id)
      else
        { id: line.id, nodes: @deansi(string), hidden: string == '' }
  join: (all) ->
    lines = []
    while line = all.pop()
      if lines.length == 0 || line.isNewline()
        lines.unshift(line.clone())
      else
        lines[0].string = line.string + lines[0].string
    lines
  after:  ->
    line = @part.lines[0]?.prev()
    line = line.prev() while line && !line.isNewline()
    line?.id
  defold: (string) ->
    if matches = string.match(/fold:(start|end):([\w]+)/)
      { type: 'fold', event: matches[1], name: matches[2] }

  deansi: (string) ->
    Log.Deansi.apply(string)

