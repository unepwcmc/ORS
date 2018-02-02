#--
# Copyright (c) 2010 Ryan Grove <ryan@wonko.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#++

class OrtSanitize

  def self.white_space_cleanse text_obj, sanitize=true
    if text_obj
      text_obj = text_obj.gsub("<br />", "\n")
      text_obj = text_obj.gsub("\t", " ")
      if sanitize
        sanitized = Sanitize.clean(text_obj, Config::PRAWN)
      else # Used to generate pdf correctly without stripping < for text answers
        text_obj = text_obj.gsub("<", "&lt;")
      end
      return (sanitized || text_obj).gsub(/&#13;$/,"\n").gsub(/&#([0-9]*);$/," ").squeeze(" ").gsub(%r{( )*(\r)+}, "").squeeze("\n").strip
    end
    ""
  end

  module Config
    ORT = {
            :elements => [
                    'a', 'b', 'blockquote', 'br', 'caption', 'cite', 'code', 'col',
                    'colgroup', 'dd', 'dl', 'dt', 'em', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
                    'i', 'img', 'li', 'ol', 'p', 'pre', 'q', 'small', 'strike', 'strong',
                    'sub', 'sup', 'table', 'tbody', 'td', 'tfoot', 'th', 'thead', 'tr', 'u',
                    'ul', 'span', 'em'
            ],

            :attributes => {
                    'a'          => ['href', 'title', 'target'],
                    'blockquote' => ['cite'],
                    'col'        => ['span', 'width'],
                    'colgroup'   => ['span', 'width'],
                    'img'        => ['align', 'alt', 'height', 'src', 'title', 'width'],
                    'ol'         => ['start', 'type'],
                    'q'          => ['cite'],
                    'table'      => ['summary', 'width'],
                    'td'         => ['abbr', 'axis', 'colspan', 'rowspan', 'width'],
                    'th'         => ['abbr', 'axis', 'colspan', 'rowspan', 'scope',
                                     'width'],
                    'ul'         => ['type'],
                    'span'       => ['style'],
                    'p'          => ['style']
            },

            :protocols => {
                    'a'          => {'href' => ['ftp', 'http', 'https', 'mailto',
                                                :relative]},
                    'blockquote' => {'cite' => ['http', 'https', :relative]},
                    'img'        => {'src'  => ['http', 'https', :relative]},
                    'q'          => {'cite' => ['http', 'https', :relative]}
            }
    }
    PRAWN = {
      :elements => ['a', 'b', 'h1','i', 'u', 'strong'],

      :attributes => {
        'a'          => ['href', 'title', 'target']
      },

      :protocols => {
        'a'          => {'href' => ['ftp', 'http', 'https', 'mailto', :relative]}
      },
      :allowed_entities => ['amp']
    }
  end
end
