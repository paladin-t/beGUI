--[[
The MIT License

Copyright (C) 2021 - 2022 Tony Wang

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

local beClass = require 'libs/beGUI/beClass'
local beUtils = require 'libs/beGUI/beGUI_Utils'
local beWidget = require 'libs/beGUI/beGUI_Widget'

--[[
Widgets.
]]

local Label = beClass.class({
	_requestedWidth = 0,
	_alignment = 'left',
	_clip = false,
	_theme = nil,
	_shadowTheme = nil,

	-- Constructs a Label with the specific content.
	-- `content`: the content string
	ctor = function (self, content, alignment, clip_, theme, shadow)
		beWidget.Widget.ctor(self)

		self.content = content

		self._alignment = alignment or 'left'
		self._clip = clip_
		self._theme = theme
		self._shadowTheme = shadow
	end,

	__tostring = function (self)
		return 'Label'
	end,

	-- Gets the content text.
	getValue = function (self)
		return self.content
	end,
	-- Sets the content text.
	setValue = function (self, val)
		if type(val) ~= 'string' then
			val = tostring(val)
		end
		self.content = val

		return self
	end,

	alignment = function (self)
		return self._alignment
	end,
	setAlignment = function (self, val)
		self._alignment = val

		return self
	end,

	clipping = function (self)
		return self._clip
	end,
	setClipping = function (self, val)
		self._clip = val

		return self
	end,

	setTheme = function (self, theme, shadow)
		self._theme = theme
		self._shadowTheme = shadow

		return self
	end,

	resize = function (self, width, height)
		if width == -1 then
			self.height = height
			self._requestedWidth = width
		else
			self.width = width
			self.height = height
			self._requestedWidth = width
		end

		return self
	end,

	navigatable = function (self)
		return 'children'
	end,

	_update = function (self, theme, delta, dx, dy, event)
		if not self.visibility then
			return
		end

		local ox, oy = self:offset()
		local px, py = self:position()
		local x, y = dx + px + ox, dy + py + oy
		local w, h = self:size()

		local elem = theme['label']
		local shadow = self._shadowTheme and theme[self._shadowTheme] or nil
		local visible = true
		local clipped = false
		if self._clip then
			clipped = self:_beginClip(event, x, y, w, h)
			visible = clipped
		end
		if visible then
			local _1, _2, fw, _4
			local font_ = theme[self._theme or 'font']
			if self._theme and self._theme ~= 'font' then
				font(theme[self._theme].resource)
			end
			if self._alignment == 'left' then
				if shadow then
					local elem_ = theme['label_shadow']
					beUtils.textLeft(self.content, shadow, x, y, w, h, elem_.content_offset or { 1, 1 }, self.transparency)
				end
				_1, _2, fw, _4 = beUtils.textLeft(self.content, font_, x, y, w, h, elem.content_offset, self.transparency)
			elseif self._alignment == 'center' then
				if shadow then
					local elem_ = theme['label_shadow']
					beUtils.textCenter(self.content, shadow, x, y, w, h, elem_.content_offset or { 1, 1 }, self.transparency)
				end
				_1, _2, fw, _4 = beUtils.textCenter(self.content, font_, x, y, w, h, elem.content_offset, self.transparency)
			else
				if shadow then
					local elem_ = theme['label_shadow']
					beUtils.textRight(self.content, shadow, x, y, w, h, elem_.content_offset or { 1, 1 }, self.transparency)
				end
				_1, _2, fw, _4 = beUtils.textRight(self.content, font_, x, y, w, h, elem.content_offset, self.transparency)
			end
			if self._theme and self._theme ~= 'font' then
				font(theme['font'].resource)
			end
			if self.width == -1 or self._requestedWidth == -1 then
				self.width = fw
				self._requestedWidth = fw
				local w, h = self:size()
				if self.children ~= nil then
					for _, c in ipairs(self.children) do
						c:_updateLayout(w, h)
					end
				end
			end
		end
		if self._clip then
			if clipped then
				self:_endClip(event)
			end
		end

		beWidget.Widget._update(self, theme, delta, dx, dy, event)
	end
}, beWidget.Widget)

local MultilineLabel = beClass.class({
	_lineHeight = nil,
	_alignment = 'left',
	_flexWidth = false, _flexHeight = true,
	_pattern = nil, _translator = nil,
	_words = nil,
	_widgetTheme = nil,
	_theme = nil,

	-- Constructs a MultilineLabel with the specific content.
	-- `content`: the content string
	ctor = function (self, content, lineHeight, alignment)
		beWidget.Widget.ctor(self)

		self.content = content

		self._lineHeight = lineHeight
		self._alignment = alignment or 'left'
	end,

	__tostring = function (self)
		return 'MultilineLabel'
	end,

	-- Gets the content text.
	getValue = function (self)
		return self.content
	end,
	-- Sets the content text.
	setValue = function (self, val)
		if type(val) ~= 'string' then
			val = tostring(val)
		end
		if self.content == val then
			return self
		end
		self.content = val
		self._words = nil

		return self
	end,

	lineHeight = function (self)
		return self._lineHeight
	end,
	setLineHeight = function (self, val)
		if self._lineHeight == val then
			return self
		end
		self._lineHeight = val
		self._words = nil

		return self
	end,

	alignment = function (self)
		return self._alignment
	end,
	setAlignment = function (self, val)
		if self._alignment == val then
			return self
		end
		self._alignment = val
		if self._flexWidth and self._alignment and self._alignment ~= 'left' then
			warn('[WARN] beGUI.MultilineLabel\n  Cannot mix non-left alignment and flex width.')
		end
		self._words = nil

		return self
	end,

	setTheme = function (self, theme, widgetTheme)
		if self._theme == theme then
			return self
		end
		self._theme = theme
		self._widgetTheme = widgetTheme
		self._words = nil

		return self
	end,

	resize = function (self, width, height)
		beWidget.Widget.resize(self, width, height)
		self._words = nil

		return self
	end,

	-- Gets whether to calculate Widget width automatically.
	flexWidth = function (self)
		return self._flexWidth
	end,
	-- Sets whether to calculate Widget width automatically.
	setFlexWidth = function (self, val)
		if self._flexWidth == val then
			return self
		end
		self._flexWidth = val
		if self._flexWidth and self._alignment and self._alignment ~= 'left' then
			warn('[WARN] beGUI.MultilineLabel\n  Cannot mix non-left alignment and flex width.')
		end
		self._words = nil

		return self
	end,
	-- Gets whether to calculate Widget height automatically.
	flexHeight = function (self)
		return self._flexHeight
	end,
	-- Sets whether to calculate Widget height automatically.
	setFlexHeight = function (self, val)
		if self._flexHeight == val then
			return self
		end
		self._flexHeight = val
		self._words = nil

		return self
	end,

	-- Gets the word split pattern.
	pattern = function (self)
		return self._pattern
	end,
	-- Sets the word split pattern.
	setPattern = function (self, val)
		self._pattern = val

		return self
	end,

	-- Gets the word translator.
	translator = function (self)
		return self._translator
	end,
	-- Sets the word translator.
	setTranslator = function (self, val)
		self._translator = val

		return self
	end,

	navigatable = function (self)
		return 'children'
	end,

	_updateLayout = function (self, ...)
		beWidget.Widget._updateLayout(self, ...)

		self._words = nil
	end,
	_update = function (self, theme, delta, dx, dy, event)
		if not self.visibility then
			return
		end

		local ox, oy = self:offset()
		local px, py = self:position()
		local x, y = dx + px + ox, dy + py + oy
		local w, h = self:size()

		local lines = 1
		local _, height = nil, nil
		local font_ = theme[self._theme or 'font']
		if self._lineHeight ~= nil then
			height = self._lineHeight
		else
			_, height = measure('X', font_.resource, font_.margin or 1, font_.scale or 1) -- Estimate safe height.
		end
		local elem = theme[self._widgetTheme or 'multilinelabel']
		if self._theme and self._theme ~= 'font' then
			font(theme[self._theme].resource)
		end
		local color_ = nil
		if self._theme then
			color_ = font_.color
		end
		if self._words == nil then
			local flexWidth, flexHeight = self._flexWidth, self._flexHeight
			self._words = { }
			if flexWidth then
				self.width = 0
			end
			if flexHeight then
				self.height = 0
			end
			local words = beUtils.escape(self.content, font_.color, true, self._pattern, self._translator)
			local posX, posY = 0, 0
			local sizeW, sizeH = w, h
			if elem.content_offset then
				posX, posY = elem.content_offset[1], elem.content_offset[2]
				sizeW, sizeH = w - elem.content_offset[1] * 2, h - elem.content_offset[2] * 2
			end
			local initPos = Vec2.new(posX, posY)
			local lineMargin = 1
			local spaceW, _ = measure(' ', font_.resource, font_.margin or 1, font_.scale or 1)
			local lineBeginIndex, lineOffset = 1, 0
			local adjustAlignment = function (beginIndex, endIndex, beginX, endX)
				if not flexWidth then
					local diff = nil
					if self._alignment == 'center' then
						local space = w - (endX - beginX - spaceW)
						diff = space * 0.5
					elseif self._alignment == 'right' then
						local space = w - (endX - beginX - spaceW)
						diff = space
					end
					if diff then
						for i = beginIndex, endIndex, 1 do
							local word = self._words[i]
							if word then
								word.position.x = word.position.x + diff
							end
						end
					end
				end
			end
			for i, v in ipairs(words) do
				local w_, h_ = measure(v.text, font_.resource, font_.margin or 1, font_.scale or 1)
				if self._lineHeight ~= nil then
					h_ = self._lineHeight
				end
				local adjust = nil
				if v.text == '\n' then
					adjust = { lineBeginIndex - lineOffset, i - 1 - lineOffset, initPos.x, posX }
					lineBeginIndex = i + 1
					lineOffset = lineOffset + 1
					lines = lines + 1
					posX = initPos.x
					posY = posY + h_ + lineMargin
				else
					local pos = nil
					if flexWidth then
						pos = Vec2.new(posX, posY)
						posX = posX + w_
						if posX > self.width then
							self.width = posX
						end
					elseif posX + w_ - spaceW < sizeW then
						pos = Vec2.new(posX, posY)
						posX = posX + w_
					else
						adjust = { lineBeginIndex - lineOffset, i - 1 - lineOffset, initPos.x, posX }
						lineBeginIndex = i
						lines = lines + 1
						posX = initPos.x
						posY = posY + h_ + lineMargin
						pos = Vec2.new(posX, posY)
						posX = posX + w_
					end
					table.insert(
						self._words,
						{
							resource = font_.resource,
							text = v.text,
							color = v.color or color_,
							position = pos,
							margin = font_.margin,
							scale = font_.scale
						}
					)
				end
				if adjust then
					adjustAlignment(table.unpack(adjust))
				end
			end
			adjustAlignment(table.unpack({ lineBeginIndex - lineOffset, #words - lineOffset, initPos.x, posX }))
			if flexHeight then
				if lines == 1 then
					self.height = height
				else
					self.height = height * lines + lineMargin * (lines - 1)
				end
			end
		end
		local canvasWidth, canvasHeight = Canvas.main:size()
		local canvasRect = Rect.byXYWH(0, 0, canvasWidth, canvasHeight)
		for _, v in ipairs(self._words) do
			local x_, y_, w_, h_ = x + v.position.x, y + v.position.y, w, height
			local intersects = Math.intersects(canvasRect, Rect.byXYWH(x_, y_, w_, h_))
			if intersects then
				beUtils.textLeftSameLine(v.text, v, x_, y_, w_, h_, elem.content_offset, self.transparency)
			end
		end
		if self._theme and self._theme ~= 'font' then
			font(theme['font'].resource)
		end

		beWidget.Widget._update(self, theme, delta, dx, dy, event)
	end
}, beWidget.Widget)

local Url = beClass.class({
	_requestedWidth = 0,
	_alignment = 'left',
	_clip = false,
	_theme = nil,
	_pressed = false,

	-- Constructs a Url with the specific content.
	-- `content`: the content string
	ctor = function (self, content, alignment, clip_, theme)
		beWidget.Widget.ctor(self)

		self.content = content

		self._alignment = alignment or 'left'
		self._clip = clip_
		self._theme = theme
	end,

	__tostring = function (self)
		return 'Url'
	end,

	-- Gets the content text.
	getValue = function (self)
		return self.content
	end,
	-- Sets the content text.
	setValue = function (self, val)
		if type(val) ~= 'string' then
			val = tostring(val)
		end
		self.content = val

		return self
	end,

	alignment = function (self)
		return self._alignment
	end,
	setAlignment = function (self, val)
		self._alignment = val

		return self
	end,

	clipping = function (self)
		return self._clip
	end,
	setClipping = function (self, val)
		self._clip = val

		return self
	end,

	setTheme = function (self, theme)
		self._theme = theme

		return self
	end,

	resize = function (self, width, height)
		if width == -1 then
			self.height = height
			self._requestedWidth = width
		else
			self.width = width
			self.height = height
			self._requestedWidth = width
		end

		return self
	end,

	navigatable = function (self)
		return 'all'
	end,

	_update = function (self, theme, delta, dx, dy, event)
		if not self.visibility then
			return
		end

		local ox, oy = self:offset()
		local px, py = self:position()
		local x, y = dx + px + ox, dy + py + oy
		local w, h = self:size()
		local down = false
		local intersects = Math.intersects(event.mousePosition, Rect.byXYWH(x, y, w, h))
		if event.context.active and event.context.active ~= self then
			self._pressed = false
		elseif event.canceled or event.context.dragging then
			event.context.active = nil
			self._pressed = false
		elseif self._pressed then
			down = event.mouseDown
		else
			down = event.mouseDown and intersects
		end
		if down and not self._pressed then
			event.context.active = self
			self._pressed = true
		elseif not down and self._pressed then
			event.context.active = nil
			self._pressed = false
			event.context.focus = self
			self:_trigger('clicked', self)
		elseif event.context.focus == self and event.context.navigated == 'press' then
			self:_trigger('clicked', self)
			event.context.navigated = false
		end

		local elem = down and theme['url_down'] or theme['url']
		local clipped = false
		local visible = true
		if self._clip then
			clipped = self:_beginClip(event, x, y, w, h)
			visible = clipped
		end
		if visible then
			local theme_ = theme[self._theme or intersects and 'font_url_hover' or 'font_url']
			local _, fy, fw, fh
			if theme_.resource ~= theme['font'].resource then
				font(theme_.resource)
			end
			if down and intersects then
				if not self.transparency then
					rect(x, y, x + w, y + h, true, theme['font_url'].color)
				end
			end
			if w <= 0 and h <= 0 then
				local w_, h_ = measure(self.content, theme_.resource, theme_.margin or 1, theme_.scale or 1)
				self:resize(w_, h_)
			end
			if self._alignment == 'left' then
				_, fy, fw, fh = beUtils.textLeft(self.content, theme_, x, y, w, h, elem.content_offset, self.transparency)
			elseif self._alignment == 'center' then
				_, fy, fw, fh = beUtils.textCenter(self.content, theme_, x, y, w, h, elem.content_offset, self.transparency)
			else
				_, fy, fw, fh = beUtils.textRight(self.content, theme_, x, y, w, h, elem.content_offset, self.transparency)
			end
			if self.width == -1 or self._requestedWidth == -1 then
				self.width = fw
				self._requestedWidth = fw
				local w, h = self:size()
				if self.children ~= nil then
					for _, c in ipairs(self.children) do
						c:_updateLayout(w, h)
					end
				end
			end
			if intersects then
				if not self.transparency then
					line(x, fy + fh, x + w, fy + fh, theme_.color)
				end
			end
			if theme_.resource ~= theme['font'].resource then
				font(theme['font'].resource)
			end
		end
		if self._clip then
			if clipped then
				self:_endClip(event)
			end
		end

		beWidget.Widget._update(self, theme, delta, dx, dy, event)
	end
}, beWidget.Widget)

local InputBox = beClass.class({
	_placeholder = nil,
	_pressed = false,
	_size = nil,
	_ticks = 0,
	_theme = nil,
	_placeholderTheme = nil,

	-- Constructs an InputBox with the specific content.
	-- `content`: the content string
	-- `placeholder`: the placeholder string when there's no input yet
	ctor = function (self, content, placeholder)
		beWidget.Widget.ctor(self)

		self.content = content

		self._placeholder = placeholder
	end,

	__tostring = function (self)
		return 'InputBox'
	end,

	-- Gets the content text.
	getValue = function (self)
		return self.content
	end,
	-- Sets the content text.
	setValue = function (self, val)
		if type(val) ~= 'string' then
			val = tostring(val)
		end
		self.content = val
		self._size = nil
		self:_trigger('changed', self, self.content)

		return self
	end,

	setTheme = function (self, theme, placeholder)
		self._theme = theme
		self._placeholderTheme = placeholder

		return self
	end,

	placeholder = function (self)
		return self._placeholder
	end,
	setPlaceholder = function (self, val)
		self._placeholder = val

		return self
	end,

	navigatable = function (self)
		return 'all'
	end,

	_updateLayout = function (self, ...)
		beWidget.Widget._updateLayout(self, ...)

		self._size = nil
	end,
	_update = function (self, theme, delta, dx, dy, event)
		if not self.visibility then
			return
		end

		local ox, oy = self:offset()
		local px, py = self:position()
		local x, y = dx + px + ox, dy + py + oy
		local w, h = self:size()
		local down = false
		if event.context.active and event.context.active ~= self then
			self._pressed = false
		elseif event.canceled or event.context.dragging then
			event.context.active = nil
			self._pressed = false
		elseif self._pressed then
			down = event.mouseDown
		else
			down = event.mouseDown and Math.intersects(event.mousePosition, Rect.byXYWH(x, y, w, h))
		end
		if down and not self._pressed then
			event.context.active = self
			self._pressed = true
		elseif not down and self._pressed then
			event.context.active = nil
			self._pressed = false
			local input_ = input('Input', self.content)
			if input_ then
				event.context.focus = self
				self:setValue(input_)
			end
		elseif event.context.focus == self and event.context.navigated == 'press' then
			event.context.active = nil
			self._pressed = false
			local input_ = input('Input', self.content)
			if input_ then
				event.context.focus = self
				self:setValue(input_)
			end
			event.context.navigated = false
		end

		local font_ = theme[self._theme or 'font']
		if self._theme and self._theme ~= 'font' then
			font(theme[self._theme].resource)
		end
		local placeholder = theme[self._placeholderTheme or 'font_placeholder']
		if self._size == nil then
			local w_, h_ = measure(self.content, font_.resource, font_.margin or 1, font_.scale or 1)
			self._size = Vec2.new(w_, h_)
		end
		self._ticks = self._ticks + delta
		if self._ticks > 0.8 then
			self._ticks = self._ticks - 0.8
		end
		local elem = theme['inputbox']
		beUtils.tex9Grid(elem, x, y, w, h, nil, self.transparency, nil)
		local clipped = self:_beginClip(event, x, y, w - elem.content_offset[1], h)
		if clipped then
			local caretX = x + self._size.x
			if #self.content ~= 0 then
				local txtW = self._size.x + elem.content_offset[1] * 2 + 14
				if txtW <= w then
					beUtils.textLeft(self.content, font_, x, y, w, h, elem.content_offset, self.transparency)
				else
					beUtils.textLeft(self.content, font_, x + (w - txtW), y, w, h, elem.content_offset, self.transparency)
					local caretW = measure('_', font_.resource, font_.margin or 1, font_.scale or 1)
					caretX = x + w - caretW - 10
				end
			else
				beUtils.textLeft(self._placeholder, placeholder, x, y, w, h, elem.content_offset, self.transparency)
			end
			if self._ticks < 0.4 then
				beUtils.textLeft('_', font_, caretX, y + (elem.content_offset[3] or 0), w, h, elem.content_offset, self.transparency)
			end
		end
		if clipped then
			self:_endClip(event)
		end
		if self._theme and self._theme ~= 'font' then
			font(theme['font'].resource)
		end

		beWidget.Widget._update(self, theme, delta, dx, dy, event)
	end
}, beWidget.Widget)

local Picture = beClass.class({
	_stretched = false,
	_permeation = nil,
	_color = nil,

	-- Constructs a Picture with the specific content.
	-- `content`: the content Texture
	-- `stretched`: whether to use 9-grid-based splitting and stretching
	-- `permeation`: whether to use permeation correction
	ctor = function (self, content, stretched, permeation)
		beWidget.Widget.ctor(self)

		self.content = content

		self._stretched = not not stretched
		self._permeation = permeation
	end,

	__tostring = function (self)
		return 'Picture'
	end,

	-- Sets the content Texture.
	setValue = function (self, content)
		self.content = content

		return self
	end,

	stretched = function (self)
		return self._stretched
	end,
	setStretched = function (self, val)
		self._stretched = val

		return self
	end,

	permeation = function (self)
		return self._permeation
	end,
	setPermeation = function (self, val)
		self._permeation = val

		return self
	end,

	color = function (self)
		return self._color
	end,
	setColor = function (self, val)
		self._color = val

		return self
	end,

	navigatable = function (self)
		return 'children'
	end,

	_update = function (self, theme, delta, dx, dy, event)
		if not self.visibility then
			return
		end

		local ox, oy = self:offset()
		local px, py = self:position()
		local x, y = dx + px + ox, dy + py + oy
		local w, h = self:size()

		if self.content then
			if self._stretched then
				beUtils.tex9Grid(self.content, x, y, w, h, self._permeation, self.transparency, self._color)
			else
				local sx, sy, sw, sh = nil, nil, nil, nil
				if self.content.area then
					sx, sy, sw, sh = self.content.area[1], self.content.area[2], self.content.area[3], self.content.area[4]
				end
				if self._color or self.transparency then
					local col = nil
					if self._color then
						if self.transparency then
							col = Color.new(self._color.r, self._color.g, self._color.b, self._color.a * (self.transparency / 255))
						else
							col = self._color
						end
					else
						if self.transparency then
							col = Color.new(255, 255, 255, self.transparency)
						end
					end
					tex(self.content.resource, x, y, w, h, sx, sy, sw, sh, 0, Vec2.new(0.5, 0.5), false, false, col)
				else
					tex(self.content.resource, x, y, w, h, sx, sy, sw, sh)
				end
			end
		end

		beWidget.Widget._update(self, theme, delta, dx, dy, event)
	end
}, beWidget.Widget)

local Button = beClass.class({
	_theme = nil,
	_themeNormal = nil, _themeDown = nil, _themeDisabled = nil,
	_enabled = true,
	_pressed = false,

	-- Constructs a Button with the specific content.
	-- `content`: the content string
	ctor = function (self, content)
		beWidget.Widget.ctor(self)

		self.content = content
	end,

	__tostring = function (self)
		return 'Button'
	end,

	setValue = function (self, content)
		self.content = content

		return self
	end,

	setTheme = function (self, theme, themeNormal, themeDown, themeDisabled)
		self._theme = theme
		self._themeNormal, self._themeDown, self._themeDisabled = themeNormal, themeDown, themeDisabled

		return self
	end,

	enabled = function (self)
		return self._enabled
	end,
	setEnabled = function (self, val)
		self._enabled = val

		return self
	end,

	navigatable = function (self)
		return 'all'
	end,

	_update = function (self, theme, delta, dx, dy, event)
		if not self.visibility then
			return
		end

		local ox, oy = self:offset()
		local px, py = self:position()
		local x, y = dx + px + ox, dy + py + oy
		local w, h = self:size()
		local down = false
		if event.context.active and event.context.active ~= self then
			self._pressed = false
		elseif event.canceled or event.context.dragging then
			event.context.active = nil
			self._pressed = false
		elseif self._pressed then
			down = event.mouseDown
		else
			down = event.mouseDown and Math.intersects(event.mousePosition, Rect.byXYWH(x, y, w, h))
		end
		if down and not self._pressed then
			event.context.active = self
			self._pressed = true
		elseif not down and self._pressed then
			event.context.active = nil
			self._pressed = false
			event.context.focus = self
			if self._enabled then
				self:_trigger('clicked', self)
			end
		elseif event.context.focus == self and event.context.navigated == 'press' then
			if self._enabled then
				self:_trigger('clicked', self)
			end
			event.context.navigated = false
		end

		local font_ = theme[self._theme or 'font']
		local elem = nil
		if self._enabled then
			elem = down and theme[self._themeDown or 'button_down'] or theme[self._themeNormal or 'button']
		else
			elem = theme[self._themeDisabled or 'button_disabled']
		end
		beUtils.tex9Grid(elem, x, y, w, h, nil, self.transparency, nil)
		if self._theme and self._theme ~= 'font' then
			font(theme[self._theme].resource)
		end
		beUtils.textCenter(self.content, font_, x, y, w, h, elem.content_offset, self.transparency)
		if self._theme and self._theme ~= 'font' then
			font(theme['font'].resource)
		end

		beWidget.Widget._update(self, theme, delta, dx, dy + (down and self._enabled and 1 or 0), event)
	end
}, beWidget.Widget)

local PictureButton = beClass.class({
	_enabled = true,
	_pressed = false,
	_pressedTimestamp = nil,
	_repeat = false,
	_background = false,

	_theme = nil,
	_themeBackgroundNormal = nil,
	_themeBackgroundPressed = nil,
	_themeBackgroundDisabled = nil,
	_themeNormal = nil,
	_themePressed = nil,
	_themeDisabled = nil,

	-- Constructs a PictureButton with the specific content.
	-- `content`: the content Texture
	-- `repeat_`: whether to enable repeating event
	ctor = function (self, content, repeat_, theme, background)
		beWidget.Widget.ctor(self)

		self.content = content

		self._repeat = repeat_
		self._background = background

		self._themeBackgroundNormal = theme.background_normal
		self._themeBackgroundPressed = theme.background_pressed
		self._themeBackgroundDisabled = theme.background_disabled
		self._themeNormal = theme.normal
		self._themePressed = theme.pressed
		self._themeDisabled = theme.disabled
	end,

	__tostring = function (self)
		return 'PictureButton'
	end,

	setTheme = function (self, theme, widgetTheme)
		self._theme = theme
		self._themeBackgroundNormal = widgetTheme.background_normal
		self._themeBackgroundPressed = widgetTheme.background_pressed
		self._themeBackgroundDisabled = widgetTheme.background_disabled
		self._themeNormal = widgetTheme.normal
		self._themePressed = widgetTheme.pressed
		self._themeDisabled = widgetTheme.disabled

		return self
	end,

	enabled = function (self)
		return self._enabled
	end,
	setEnabled = function (self, val)
		self._enabled = val

		return self
	end,

	navigatable = function (self)
		return 'all'
	end,

	_update = function (self, theme, delta, dx, dy, event)
		if not self.visibility then
			return
		end

		local ox, oy = self:offset()
		local px, py = self:position()
		local x, y = dx + px + ox, dy + py + oy
		local w, h = self:size()
		local down = false
		if event.context.active and event.context.active ~= self then
			self._pressed = false
		elseif event.canceled or event.context.dragging then
			event.context.active = nil
			self._pressed = false
		elseif self._pressed then
			down = event.mouseDown
		else
			down = event.mouseDown and Math.intersects(event.mousePosition, Rect.byXYWH(x, y, w, h))
		end
		if down and not self._pressed then
			event.context.active = self
			self._pressed = true
			self._pressedTimestamp = DateTime.ticks()
		elseif not down and self._pressed then
			event.context.active = nil
			self._pressed = false
			self._pressedTimestamp = nil
			if self:navigatable() then
				event.context.focus = self
			elseif self.parent and self.parent:navigatable() then
				event.context.focus = self.parent
			end
			if self._enabled then
				self:_trigger('clicked', self)
			end
		elseif down and self._pressed and self._repeat then
			local diff = DateTime.toSeconds(DateTime.ticks() - self._pressedTimestamp)
			if diff > 0.5 then
				if self:navigatable() then
					event.context.focus = self
				elseif self.parent and self.parent:navigatable() then
					event.context.focus = self.parent
				end
				if self._enabled then
					self:_trigger('clicked', self)
				end
			end
		elseif event.context.focus == self and event.context.navigated == 'press' then
			if self._enabled then
				self:_trigger('clicked', self)
			end
			event.context.navigated = false
		end

		if self._background then
			local down_, up_ = theme[self._themeBackgroundPressed or 'button_down'], theme[self._themeBackgroundNormal or 'button']
			local elem = down and down_ or up_
			if not self._enabled then
				elem = theme[self._themeBackgroundDisabled or 'button_disabled']
			end
			beUtils.tex9Grid(elem, x, y, w, h, 0, self.transparency, nil)
		end

		local elem = down and theme[self._themePressed] or theme[self._themeNormal]
		if not self._enabled then
			elem = theme[self._themeDisabled]
		end
		local img = elem.resource
		local area = elem.area
		local offsetX, offsetY = 0, 0
		if elem.content_offset then
			offsetX, offsetY = elem.content_offset[1], elem.content_offset[2]
		end
		if self.transparency then
			local col = Color.new(255, 255, 255, self.transparency)
			tex(img, x + (w - area[3]) * 0.5 + offsetX, y + (h - area[4]) * 0.5 + offsetY, area[3], area[4], area[1], area[2], area[3], area[4], 0, Vec2.new(0.5, 0.5), false, false, col)
		else
			tex(img, x + (w - area[3]) * 0.5 + offsetX, y + (h - area[4]) * 0.5 + offsetY, area[3], area[4], area[1], area[2], area[3], area[4])
		end
		if self.content then
			local font_ = theme[self._theme or 'font']
			if self._theme and self._theme ~= 'font' then
				font(theme[self._theme].resource)
			end
			beUtils.textCenter(self.content, font_, x, y, w, h, elem.content_offset, self.transparency)
			if self._theme and self._theme ~= 'font' then
				font(theme['font'].resource)
			end
		end

		beWidget.Widget._update(self, theme, delta, dx, dy, event)
	end
}, beWidget.Widget)

local CheckBox = beClass.class({
	_enabled = true,
	_pressed = false,
	_value = false,

	-- Constructs a CheckBox with the specific content.
	-- `content`: the content string
	-- `value`: the initial checked state
	ctor = function (self, content, value)
		beWidget.Widget.ctor(self)

		self.content = content

		self._value = not not value
	end,

	__tostring = function (self)
		return 'CheckBox'
	end,

	-- Gets whether this Widget is checked.
	getValue = function (self)
		return self._value
	end,
	-- Sets whether this Widget is checked.
	setValue = function (self, val)
		if self._value == val then
			return self
		end
		self._value = val
		self:_trigger('changed', self, self._value)

		return self
	end,

	setContent = function (self, val)
		self.content = content

		return self
	end,

	enabled = function (self)
		return self._enabled
	end,
	setEnabled = function (self, val)
		self._enabled = val

		return self
	end,

	navigatable = function (self)
		return 'all'
	end,

	_update = function (self, theme, delta, dx, dy, event)
		if not self.visibility then
			return
		end

		local ox, oy = self:offset()
		local px, py = self:position()
		local x, y = dx + px + ox, dy + py + oy
		local w, h = self:size()
		local down = false
		if event.context.active and event.context.active ~= self then
			self._pressed = false
		elseif event.canceled or event.context.dragging then
			event.context.active = nil
			self._pressed = false
		elseif self._pressed then
			down = event.mouseDown
		else
			down = event.mouseDown and Math.intersects(event.mousePosition, Rect.byXYWH(x, y, w, h))
		end
		if down and not self._pressed then
			event.context.active = self
			self._pressed = true
		elseif not down and self._pressed then
			event.context.active = nil
			self._pressed = false
			event.context.focus = self
			if self._enabled then
				self:setValue(not self._value)
			end
		elseif event.context.focus == self and event.context.navigated == 'press' then
			if self._enabled then
				self:setValue(not self._value)
			end
			event.context.navigated = false
		elseif event.context.focus == self and event.context.navigated == 'press' then
			if self._enabled then
				self:setValue(not self._value)
			end
			event.context.navigated = false
		end

		local normal, pressed = nil, nil
		if self._enabled then
			normal, pressed = theme['checkbox'], theme['checkbox_selected']
		else
			normal, pressed = theme['checkbox_disabled'], theme['checkbox_selected_disabled']
		end
		if self._value then
			normal, pressed = pressed, normal
		end
		local elem = (self._enabled and down) and pressed or normal
		local img = elem.resource
		local area = elem.area
		if self.transparency then
			local col = Color.new(255, 255, 255, self.transparency)
			tex(img, x, y + (h - area[4]) * 0.5, area[3], area[4], area[1], area[2], area[3], area[4], 0, Vec2.new(0.5, 0.5), false, false, col)
		else
			tex(img, x, y + (h - area[4]) * 0.5, area[3], area[4], area[1], area[2], area[3], area[4])
		end
		beUtils.textLeft(self.content, theme['font'], x, y, w, h, elem.content_offset, self.transparency)

		beWidget.Widget._update(self, theme, delta, dx, dy, event)
	end
}, beWidget.Widget)

local RadioBox = beClass.class({
	_pressed = false,
	_value = false,

	-- Constructs a RadioBox with the specific content.
	-- `content`: the content string
	-- `value`: the initial checked state
	ctor = function (self, content, value)
		beWidget.Widget.ctor(self)

		self.content = content

		self._value = not not value
	end,

	__tostring = function (self)
		return 'RadioBox'
	end,

	-- Gets whether this Widget is checked.
	getValue = function (self)
		return self._value
	end,
	-- Sets whether this Widget is checked; not recommended to call this manually.
	setValue = function (self, val)
		if self._value == val then
			return self
		end
		self._value = val
		self:_trigger('changed', self, self._value)

		return self
	end,

	setContent = function (self, val)
		self.content = content

		return self
	end,

	navigatable = function (self)
		return 'all'
	end,

	_update = function (self, theme, delta, dx, dy, event)
		if not self.visibility then
			return
		end

		local ox, oy = self:offset()
		local px, py = self:position()
		local x, y = dx + px + ox, dy + py + oy
		local w, h = self:size()
		local down = false
		if event.context.active and event.context.active ~= self then
			self._pressed = false
		elseif event.canceled or event.context.dragging then
			event.context.active = nil
			self._pressed = false
		elseif self._pressed then
			down = event.mouseDown
		else
			down = event.mouseDown and Math.intersects(event.mousePosition, Rect.byXYWH(x, y, w, h))
		end
		if down and not self._pressed then
			event.context.active = self
			self._pressed = true
		elseif not down and self._pressed then
			event.context.active = nil
			self._pressed = false
			if not self._value then
				event.context.focus = self
				self:setValue(not self._value)
				if self._value and self.parent then
					self.parent:foreachChild(function (brother)
						if brother == self then
							return
						end
						if beClass.is(brother, beGUI.RadioBox) then
							brother:setValue(false)
						end
					end)
				end
			end
		elseif event.context.focus == self and event.context.navigated == 'press' then
			event.context.active = nil
			self._pressed = false
			if not self._value then
				self:setValue(not self._value)
				if self._value and self.parent then
					self.parent:foreachChild(function (brother)
						if brother == self then
							return
						end
						if beClass.is(brother, beGUI.RadioBox) then
							brother:setValue(false)
						end
					end)
				end
			end
			event.context.navigated = false
		end

		local elem = self._value and theme['radiobox_selected'] or theme['radiobox']
		local img = elem.resource
		local area = elem.area
		if self.transparency then
			local col = Color.new(255, 255, 255, self.transparency)
			tex(img, x, y + (h - area[4]) * 0.5, area[3], area[4], area[1], area[2], area[3], area[4], 0, Vec2.new(0.5, 0.5), false, false, col)
		else
			tex(img, x, y + (h - area[4]) * 0.5, area[3], area[4], area[1], area[2], area[3], area[4])
		end
		beUtils.textLeft(self.content, theme['font'], x, y, w, h, elem.content_offset, self.transparency)

		beWidget.Widget._update(self, theme, delta, dx, dy, event)
	end
}, beWidget.Widget)

local ComboBox = beClass.class({
	_pressed = false,
	_value = -1,
	_scrollable = true,

	_buttonLeft = nil,
	_buttonRight = nil,

	-- Constructs a ComboBox with the specific content.
	-- `content`: list of string
	-- `value`: the selected index number
	ctor = function (self, content, value)
		beWidget.Widget.ctor(self)

		self.content = { }
		for _, v in ipairs(content) do
			self:addItem(v)
		end

		if value then
			self._value = value
		else
			self._value = #self.content ~= 0 and 1 or -1
		end

		self._buttonLeft = PictureButton.new(
			'', false,
			{ normal = 'combobox_button_left', pressed = 'combobox_button_left_down' }
		)
			:put(0, 0)
			:on('clicked', function (sender)
				if #self.content ~= 0 then
					local val = self._value - 1
					if val < 1 then
						val = #self.content
					end
					self:setValue(val)
				end
			end)
		self._buttonRight = PictureButton.new(
			'', false,
			{ normal = 'combobox_button_right', pressed = 'combobox_button_right_down' }
		)
			:put(0, 0)
			:on('clicked', function (sender)
				if #self.content ~= 0 then
					local val = self._value + 1
					if val > #self.content then
						val = 1
					end
					self:setValue(val)
				end
			end)
		self._buttonLeft.navigatable = function (self)
			return nil
		end
		self._buttonRight.navigatable = function (self)
			return nil
		end
		self:addChild(self._buttonLeft)
		self:addChild(self._buttonRight)
	end,

	__tostring = function (self)
		return 'ComboBox'
	end,

	-- Gets the item text at the specific index.
	getItemAt = function (self, index)
		if index <= 0 or index > #self.content then
			return nil
		end

		return self.content[index]
	end,
	-- Adds an item string with the specific content text.
	addItem = function (self, item)
		table.insert(self.content, item)

		return self
	end,
	-- Removes the item at the specific index.
	removeItemAt = function (self, index)
		if index <= 0 or index >= #self.content then
			return false
		end
		table.remove(self.content, index)
		if #self.content == 0 then
			self._value = -1
		else
			if self._value > #self.content then
				self._value = #self.content
				self:_trigger('changed', self, self._value)
			end
		end

		return true
	end,
	-- Clears all items.
	clearItems = function (self)
		self.content = { }
		if self._value ~= -1 then
			self._value = -1
		end

		return self
	end,

	-- Gets the selected index.
	getValue = function (self)
		return self._value
	end,
	-- Sets the selected index.
	setValue = function (self, val)
		if self._value == val then
			return self
		end
		if val <= 0 or val > #self.content then
			return self
		end
		self._value = val
		self:_trigger('changed', self, self._value)

		return self
	end,

	-- Gets whether can scroll the widget by mouse wheel.
	scrollable = function (self)
		return self._scrollable
	end,
	-- Sets whether can scroll the widget by mouse wheel.
	setScrollable = function (self, val)
		self._scrollable = val

		return self
	end,

	navigatable = function (self)
		return 'all'
	end,

	_update = function (self, theme, delta, dx, dy, event)
		if not self.visibility then
			return
		end

		local ox, oy = self:offset()
		local px, py = self:position()
		local x, y = dx + px + ox, dy + py + oy
		local w, h = self:size()
		local elemL = theme['combobox_button_left']
		local areaL = elemL.area
		local elemR = theme['combobox_button_right']
		local areaR = elemR.area
		self._buttonLeft
			:put(0, (h - areaL[4]) * 0.5)
			:resize(areaL[3], areaL[4])
		self._buttonRight
			:put(w - areaR[3], (h - areaR[4]) * 0.5)
			:resize(areaR[3], areaR[4])
		x = x + areaL[3]
		w = w - areaL[3] - areaR[3]
		local down = false
		local intersects = Math.intersects(event.mousePosition, Rect.byXYWH(x, y, w, h))
		if event.context.active and event.context.active ~= self then
			self._pressed = false
		elseif event.canceled or event.context.dragging then
			event.context.active = nil
			self._pressed = false
		elseif self._pressed then
			down = event.mouseDown
		else
			down = event.mouseDown and intersects
		end
		if down and not self._pressed then
			event.context.active = self
			self._pressed = true
		elseif not down and self._pressed then
			event.context.active = nil
			self._pressed = false
			event.context.focus = self
			if #self.content ~= 0 then
				local val = self._value + 1
				if val > #self.content then
					val = 1
				end
				self:setValue(val)
			end
		elseif intersects and event.mouseWheel < 0 and self._scrollable then
			if #self.content ~= 0 then
				local val = self._value - 1
				if val < 1 then
					val = #self.content
				end
				self:setValue(val)
			end
		elseif intersects and event.mouseWheel > 0 and self._scrollable then
			if #self.content ~= 0 then
				local val = self._value + 1
				if val > #self.content then
					val = 1
				end
				self:setValue(val)
			end
		elseif event.context.focus == self and event.context.navigated == 'dec' then
			self._buttonLeft:_trigger('clicked', self._buttonLeft)
			event.context.navigated = false
		elseif event.context.focus == self and (event.context.navigated == 'inc' or event.context.navigated == 'press') then
			self._buttonRight:_trigger('clicked', self._buttonRight)
			event.context.navigated = false
		end

		local elem = theme['combobox']
		local img = elem.resource
		local area = elem.area
		beUtils.tex3Grid(elem, x - 1, y + (h - area[4]) * 0.5, math.ceil(w + 2), area[4], nil, self.transparency, nil)
		local item = self:getItemAt(self:getValue())
		if item ~= nil then
			local clipped = self:_beginClip(event, x, y, w, h)
			if clipped then
				if type(item) == 'string' then
					beUtils.textLeft(item, theme['font'], x, y, w, h, elem.content_offset, self.transparency)
				else
					local area = item.area
					if self.transparency then
						local col = Color.new(255, 255, 255, self.transparency)
						tex(item.resource, x, y + 1, area[3], area[4], area[1], area[2], area[3], area[4], 0, Vec2.new(0.5, 0.5), false, false, col)
					else
						tex(item.resource, x, y + 1, area[3], area[4], area[1], area[2], area[3], area[4])
					end
				end
			end
			if clipped then
				self:_endClip(event)
			end
		end

		beWidget.Widget._update(self, theme, delta, dx, dy, event)
	end
}, beWidget.Widget)

local NumberBox = beClass.class({
	_pressed = false,
	_value = -1,
	_step = 1,
	_minValue = nil,
	_maxValue = nil,
	_trim = nil,
	_format = nil,
	_valueTheme = nil,
	_scrollable = true,

	_buttonUp = nil,
	_buttonDown = nil,

	-- Constructs a NumberBox with the specific value.
	-- `value`: the initial value number
	-- `step`: the changing step
	-- `min`: the minumum limit
	-- `max`: the maximum limit
	-- `trim`: optional, used to trim before value setting
	-- `format`: optional, used to format value for output
	ctor = function (self, value, step, min, max, trim, format)
		beWidget.Widget.ctor(self)

		if min > max then
			error('Invalid bounds.')
		end
		if value and min and value < min then
			value = min
		end
		if value and max and value > max then
			value = max
		end
		self._value = value
		self._step = step
		self._minValue = min
		self._maxValue = max
		self._trim = trim
		self._format = format or tostring

		self._buttonUp = PictureButton.new(
			'', true,
			{ normal = 'numberbox_button_up', pressed = 'numberbox_button_up_down' }
		)
			:put(0, 0)
			:on('clicked', function (sender)
				local val = self._value + self._step
				self:setValue(val)
			end)
		self._buttonDown = PictureButton.new(
			'', true,
			{ normal = 'numberbox_button_down', pressed = 'numberbox_button_down_down' }
		)
			:put(0, 0)
			:on('clicked', function (sender)
				local val = self._value - self._step
				self:setValue(val)
			end)
		self._buttonDown.navigatable = function (self)
			return nil
		end
		self._buttonUp.navigatable = function (self)
			return nil
		end
		self:addChild(self._buttonDown)
		self:addChild(self._buttonUp)
	end,

	__tostring = function (self)
		return 'NumberBox'
	end,

	-- Gets the value number.
	getValue = function (self)
		return self._value
	end,
	-- Sets the value number.
	setValue = function (self, val)
		if self._trim ~= nil then
			val = self._trim(val)
		end
		if self._value == val then
			return self
		end
		if self._minValue and val < self._minValue then
			return self
		end
		if self._maxValue and val > self._maxValue then
			return self
		end
		self._value = val
		self:_trigger('changed', self, self._value)

		return self
	end,

	getMinValue = function (self)
		return self._minValue
	end,
	setMinValue = function (self, val)
		self._minValue = val

		return self
	end,

	getMaxValue = function (self)
		return self._maxValue
	end,
	setMaxValue = function (self, val)
		self._maxValue = val

		return self
	end,

	step = function (self)
		return self._step
	end,
	setStep = function (self, val)
		self._step = val

		return self
	end,

	trim = function (self)
		return self._trim
	end,
	setTrim = function (self, val)
		self._trim = val

		return self
	end,

	format = function (self)
		return self._format
	end,
	setFormat = function (self, val)
		self._format = val

		return self
	end,

	setValueTheme = function (self, val)
		self._valueTheme = val

		return self
	end,

	-- Gets whether can scroll the widget by mouse wheel.
	scrollable = function (self)
		return self._scrollable
	end,
	-- Sets whether can scroll the widget by mouse wheel.
	setScrollable = function (self, val)
		self._scrollable = val

		return self
	end,

	navigatable = function (self)
		return 'all'
	end,

	_update = function (self, theme, delta, dx, dy, event)
		if not self.visibility then
			return
		end

		local ox, oy = self:offset()
		local px, py = self:position()
		local x, y = dx + px + ox, dy + py + oy
		local w, h = self:size()
		local elemU = theme['numberbox_button_up']
		local areaU = elemU.area
		local elemD = theme['numberbox_button_down']
		local areaD = elemD.area
		self._buttonUp
			:put(w - areaD[3], (h - areaD[4]) * 0.5)
			:resize(areaU[3], areaU[4])
		self._buttonDown
			:put(w - areaU[3] - areaD[3], (h - areaD[4]) * 0.5)
			:resize(areaD[3], areaD[4])
		w = w - areaU[3] - areaD[3]
		local down = false
		local intersects = Math.intersects(event.mousePosition, Rect.byXYWH(x, y, w, h))
		if event.context.active and event.context.active ~= self then
			self._pressed = false
		elseif event.canceled or event.context.dragging then
			event.context.active = nil
			self._pressed = false
		elseif self._pressed then
			down = event.mouseDown
		else
			down = event.mouseDown and intersects
		end
		if down and not self._pressed then
			event.context.active = self
			self._pressed = true
		elseif not down and self._pressed then
			event.context.active = nil
			self._pressed = false
			event.context.focus = self
			local val = self._value + self._step
			self:setValue(val)
		elseif intersects and event.mouseWheel < 0 and self._scrollable then
			local val = self._value - self._step
			self:setValue(val)
		elseif intersects and event.mouseWheel > 0 and self._scrollable then
			local val = self._value + self._step
			self:setValue(val)
		elseif event.context.focus == self and event.context.navigated == 'dec' then
			self._buttonDown:_trigger('clicked', self._buttonDown)
			event.context.navigated = false
		elseif event.context.focus == self and (event.context.navigated == 'inc' or event.context.navigated == 'press') then
			self._buttonUp:_trigger('clicked', self._buttonUp)
			event.context.navigated = false
		end

		local elem = theme['numberbox']
		local img = elem.resource
		local area = elem.area
		beUtils.tex3Grid(elem, x, y + (h - area[4]) * 0.5, math.ceil(w + 1), area[4], nil, self.transparency, nil)
		local item = self._format(self._value)
		local clipped = self:_beginClip(event, x, y, w, h)
		if clipped then
			if self._valueTheme and self._valueTheme ~= 'font' then
				font(theme[self._valueTheme].resource)
			end
			local font_ = theme[self._valueTheme or 'font']
			beUtils.textLeft(item, font_, x + 1, y, w, h, elem.content_offset, self.transparency)
			if self._valueTheme and self._valueTheme ~= 'font' then
				font(theme['font'].resource)
			end
		end
		if clipped then
			self:_endClip(event)
		end

		beWidget.Widget._update(self, theme, delta, dx, dy, event)
	end
}, beWidget.Widget)

local ProgressBar = beClass.class({
	_max = 0,
	_shadow = nil,
	_color = nil,
	_reversed = nil,
	_theme = nil,
	_shadowTicks = 0,

	-- Constructs a ProgressBar.
	-- `max`: the maximum value
	-- `color`: the color for the completed bar
	-- `increasing`: indicates whether to increase from left to right, or reversed, one in `'left'`, `'right'`
	ctor = function (self, max, color, increasing)
		beWidget.Widget.ctor(self)

		self.content = 0

		self._max = max
		self._color = color or Color.new(0, 0, 0)
		self._reversed = increasing == 'left'
	end,

	__tostring = function (self)
		return 'ProgressBar'
	end,

	getValue = function (self)
		return self.content
	end,
	setValue = function (self, val)
		if self.content == val then
			return self
		end
		self.content = val
		self:_trigger('changed', self, self.content, self._max, self._shadow)

		return self
	end,

	getMaxValue = function (self)
		return self._max
	end,
	setMaxValue = function (self, val)
		if self._max == val then
			return self
		end
		self._max = val
		self:_trigger('changed', self, self.content, self._max, self._shadow)

		return self
	end,

	color = function (self)
		return self._color
	end,
	setColor = function (self, val)
		self._color = val or Color.new(0, 0, 0)

		return self
	end,

	getShadowValue = function (self)
		return self._shadow
	end,
	setShadowValue = function (self, val)
		if self._shadow == val then
			return self
		end
		self._shadow = val
		self:_trigger('changed', self, self.content, self._max, self._shadow)

		return self
	end,

	setTheme = function (self, theme)
		self._theme = theme

		return self
	end,

	navigatable = function (self)
		return nil
	end,

	_update = function (self, theme, delta, dx, dy, event)
		if not self.visibility then
			return
		end

		local ox, oy = self:offset()
		local px, py = self:position()
		local x, y = dx + px + ox, dy + py + oy
		local w, h = self:size()

		local elem = theme[self._theme or 'progressbar']
		beUtils.tex9Grid(elem, x, y, w, h, 0, self.transparency, nil)
		if self._shadow == nil then
			local w_ = (w - elem.content_offset[1] * 2) * (self.content / self._max)
			local x1, y1, x2, y2 = 0, 0, 0, 0
			if self._reversed then
				x1, y1, x2, y2 =
					x - elem.content_offset[1] + beUtils.clamp(w - w_, 4, w - 2),
					y + elem.content_offset[2],
					x - elem.content_offset[1] + w - 2,
					y + h - (elem.content_offset[2] * 2 - 1)
			else
				x1, y1, x2, y2 =
					x + elem.content_offset[1],
					y + elem.content_offset[2],
					x + elem.content_offset[1] + beUtils.clamp(math.floor(w_ - 1), 0, math.floor(w - 5)),
					y + h - (elem.content_offset[2] * 2 - 1)
			end
			local showVal = self.content > 0
			if self.transparency then
				if showVal then
					local col = Color.new(self._color.r, self._color.g, self._color.b, self.transparency)
					rect(x1, y1, x2, y2, true, col)
				end
			else
				if showVal then
					rect(x1, y1, x2, y2, true, self._color)
				end
			end
		else
			local factor = 1
			if self._shadowTicks <= 0.5 then
				factor = self._shadowTicks / 0.5
			else
				factor = 1 - (self._shadowTicks - 0.5) / 0.5
			end
			local w_ = (w - elem.content_offset[1] * 2) * (self.content / self._max)
			local x1, y1, x2, y2 = 0, 0, 0, 0
			if self._reversed then
				x1, y1, x2, y2 =
					x - elem.content_offset[1] + beUtils.clamp(w - w_, 4, w - 2),
					y + elem.content_offset[2],
					x - elem.content_offset[1] + w - 2,
					y + h - (elem.content_offset[2] * 2 - 1)
			else
				x1, y1, x2, y2 =
					x + elem.content_offset[1],
					y + elem.content_offset[2],
					x + elem.content_offset[1] + beUtils.clamp(math.floor(w_ - 1), 0, math.floor(w - 5)),
					y + h - (elem.content_offset[2] * 2 - 1)
			end
			self._shadowTicks = self._shadowTicks + delta
			if self._shadowTicks >= 1 then
				self._shadowTicks = self._shadowTicks - 1
			end
			local sw = (w - elem.content_offset[1] * 2) * (self._shadow / self._max)
			local sx1, sy1, sx2, sy2 = 0, 0, 0, 0
			if self._reversed then
				sx1, sy1, sx2, sy2 =
					x - elem.content_offset[1] + beUtils.clamp(w - sw, 4, w - 2),
					y + elem.content_offset[2],
					x - elem.content_offset[1] + w - 2,
					y + h - (elem.content_offset[2] * 2 - 1)
			else
				sx1, sy1, sx2, sy2 =
					x + elem.content_offset[1],
					y + elem.content_offset[2],
					x + elem.content_offset[1] + beUtils.clamp(math.floor(sw - 1), 0, math.floor(w - 5)),
					y + h - (elem.content_offset[2] * 2 - 1)
			end
			local showVal, showShadow = self.content > 0, self._shadow > 0
			if self.content > self._shadow then
				x1, y1, x2, y2, sx1, sy1, sx2, sy2 = sx1, sy1, sx2, sy2, x1, y1, x2, y2
				showVal, showShadow = showShadow, showVal
			end
			if self.transparency then
				if showVal then
					local col = Color.new(self._color.r, self._color.g, self._color.b, self.transparency)
					rect(x1, y1, x2, y2, true, col)
				end
				if showShadow then
					local col = Color.new(self._color.r, self._color.g, self._color.b, math.floor(self.transparency * factor))
					rect(sx1, sy1, sx2, sy2, true, col)
				end
			else
				if showVal then
					rect(x1, y1, x2, y2, true, self._color)
				end
				if showShadow then
					local col = Color.new(self._color.r, self._color.g, self._color.b, math.floor(255 * factor))
					rect(sx1, sy1, sx2, sy2, true, col)
				end
			end
		end

		beWidget.Widget._update(self, theme, delta, dx, dy, event)
	end
}, beWidget.Widget)

local Slide = beClass.class({
	_pressed = false,
	_value = -1,
	_minValue = nil,
	_maxValue = nil,
	_scrollable = true,

	-- Constructs a Slide with the specific value.
	-- `value`: the initial value number
	-- `min`: the minimum limit number
	-- `max`: the maximum limit number
	ctor = function (self, value, min, max)
		beWidget.Widget.ctor(self)

		self._value = value
		self._minValue = min
		self._maxValue = max
	end,

	__tostring = function (self)
		return 'Slide'
	end,

	-- Gets the value.
	getValue = function (self)
		return self._value
	end,
	-- Sets the value.
	setValue = function (self, val)
		if self._value == val then
			return self
		end
		if self._minValue and val < self._minValue then
			return self
		end
		if self._maxValue and val > self._maxValue then
			return self
		end
		self._value = val
		self:_trigger('changed', self, self._value)

		return self
	end,

	getMinValue = function (self)
		return self._minValue
	end,
	setMinValue = function (self, val)
		self._minValue = val

		return self
	end,

	getMaxValue = function (self)
		return self._maxValue
	end,
	setMaxValue = function (self, val)
		self._maxValue = val

		return self
	end,

	-- Gets whether can scroll the widget by mouse wheel.
	scrollable = function (self)
		return self._scrollable
	end,
	-- Sets whether can scroll the widget by mouse wheel.
	setScrollable = function (self, val)
		self._scrollable = val

		return self
	end,

	navigatable = function (self)
		return 'all'
	end,

	_update = function (self, theme, delta, dx, dy, event)
		if not self.visibility then
			return
		end

		local ox, oy = self:offset()
		local px, py = self:position()
		local x, y = dx + px + ox, dy + py + oy
		local w, h = self:size()
		local down = false
		local intersects = Math.intersects(event.mousePosition, Rect.byXYWH(x, y, w, h))
		local value = self._value
		if event.context.active and event.context.active ~= self then
			self._pressed = false
		elseif event.canceled or event.context.dragging then
			event.context.active = nil
			self._pressed = false
		elseif self._pressed then
			down = event.mouseDown
		else
			down = event.mouseDown and intersects
		end
		if down and not self._pressed then
			event.context.active = self
			self._pressed = true
		elseif down and self._pressed then
			if not event.canceled then
				value = math.floor(self._minValue + (event.mousePosition.x - x) / w * (self._maxValue - self._minValue + 1))
				value = beUtils.clamp(value, self._minValue, self._maxValue)
				if value and not beUtils.isNaN(value) then
					self:setValue(value)
				end
			end
		elseif not down and self._pressed then
			event.context.active = nil
			self._pressed = false
			event.context.focus = self
			value = math.floor(self._minValue + (event.mousePosition.x - x) / w * (self._maxValue - self._minValue + 1))
			value = beUtils.clamp(value, self._minValue, self._maxValue)
			if value and not beUtils.isNaN(value) then
				self:setValue(value)
			end
		elseif intersects and event.mouseWheel < 0 and self._scrollable then
			local val = self._value - 1
			self:setValue(val)
		elseif intersects and event.mouseWheel > 0 and self._scrollable then
			local val = self._value + 1
			self:setValue(val)
		elseif event.context.focus == self and event.context.navigated == 'dec' then
			local val = self._value - 1
			self:setValue(val)
			event.context.navigated = false
		elseif event.context.focus == self and (event.context.navigated == 'inc' or event.context.navigated == 'press') then
			local val = self._value + 1
			self:setValue(val)
			event.context.navigated = false
		end

		local elem = theme['slide']
		local img = elem.resource
		local area = elem.area
		local contentX = x + area[3] * 0.5
		local contentWidth = w - area[3]
		local handleX = contentX + (value - self._minValue) / (self._maxValue - self._minValue) * contentWidth
		local black = Color.new(elem.color.r, elem.color.g, elem.color.b, self.transparency or 255)
		line(x, y + h * 0.5, x + w - 1, y + h * 0.5, black)
		rect(x, y, x + 2, y + h - 1, true, black)
		rect(x + w - 3, y, x + w - 1, y + h - 1, true, black)
		for i = self._minValue + 1, self._maxValue - 1 do
			local lineX = contentX + (i - self._minValue) / (self._maxValue - self._minValue) * contentWidth
			line(lineX, y + h * 0.1, lineX, y + h * 0.9, black)
		end
		if self.transparency then
			local col = Color.new(255, 255, 255, self.transparency)
			tex(img, handleX - area[3] * 0.5, y + (h - area[4]) * 0.5, area[3], area[4], area[1], area[2], area[3], area[4], 0, Vec2.new(0.5, 0.5), false, false, col)
		else
			tex(img, handleX - area[3] * 0.5, y + (h - area[4]) * 0.5, area[3], area[4], area[1], area[2], area[3], area[4])
		end

		beWidget.Widget._update(self, theme, delta, dx, dy, event)
	end
}, beWidget.Widget)

--[[
Exporting.
]]

return {
	Label = Label,
	MultilineLabel = MultilineLabel,
	Url = Url,
	InputBox = InputBox,
	Picture = Picture,
	Button = Button,
	PictureButton = PictureButton,
	CheckBox = CheckBox,
	RadioBox = RadioBox,
	ComboBox = ComboBox,
	NumberBox = NumberBox,
	ProgressBar = ProgressBar,
	Slide = Slide
}
