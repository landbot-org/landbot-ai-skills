# What a question's display copy (richText, HTML) says, compared with its wording (text), for `lb` and
# `draft-check`. Used with: jq -L <this folder> 'include "richtext"; ...'.
#
# Both sides are reduced to what a visitor reads: tags removed (paragraphs and <br> become line breaks),
# entities decoded (named and numeric), markdown emphasis, code and links reduced to their words, spacing
# collapsed. Every other character counts, so "$1.00" and "$100" differ and Chinese is compared as written.

def hex2int: ascii_downcase | explode | reduce .[] as $c (0; . * 16 + (if $c >= 97 then $c - 87 else $c - 48 end));
def decode_entities:
  gsub("&#(?<n>[0-9]{1,7});"; ([.n | tonumber] | implode))
  | gsub("&#[xX](?<h>[0-9a-fA-F]{1,6});"; ([.h | hex2int] | implode))
  | gsub("&nbsp;"; " ") | gsub("&lt;"; "<") | gsub("&gt;"; ">") | gsub("&quot;"; "\"") | gsub("&apos;"; "'")
  | gsub("&amp;"; "&");
def unmarkdown:
  gsub("\\[(?<t>[^\\]]*)\\]\\([^)]*\\)"; .t)
  | gsub("\\*\\*(?<t>[^*]+)\\*\\*"; .t) | gsub("\\*(?<t>[^*\\s][^*]*)\\*"; .t)
  | gsub("__(?<t>[^_]+)__"; .t) | gsub("(?<![A-Za-z0-9])_(?<t>[^_\\s][^_]*)_(?![A-Za-z0-9])"; .t)
  | gsub("~(?<t>[^~]+)~"; .t) | gsub("`(?<t>[^`]+)`"; .t);
def squash: gsub("\\s+"; " ") | ltrimstr(" ") | rtrimstr(" ");
def rich_plain: gsub("<br\\s*/?>"; "\n") | gsub("</p>\\s*<p[^>]*>"; "\n") | gsub("<[^>]*>"; "") | decode_entities | unmarkdown | squash;
def text_plain: unmarkdown | squash;
# Text that itself carries HTML (a builder-authored embed, for example) cannot be compared this way.
def comparable($text): ($text | test("<[a-zA-Z/!]")) | not;
# An entity still there after decoding means the display copy is not understood: treat it as different.
def rich_differs($text; $rich): ($rich | rich_plain) as $r | ($r | test("&[#a-zA-Z0-9]+;")) or ($r != ($text | text_plain));
