#!/usr/bin/env ruby -wKU
require "fileutils"
@html="src/qatool.html"
@maincss="src/css/main.css"
@maincss_compressed="src/build/main.css"
@qatooljs="src/js/qatool.js"
@qatooljs_compressed="src/build/qatool.js"
@prototypejs="src/js/prototype_c.js"
@swfobjectjs="src/js/swfobject.js"
@livepipejs="src/js/livepipe.net_c.js"
@finaloutfile="lib/qatool.html"
FileUtils.rm_rf(@maincss_compressed)
FileUtils.rm_rf(@qatooljs_compressed)
system("java -jar src/yuic.jar --nomunge --line-break 100 --type css -o '#{@maincss_compressed}' #{@maincss}")
system("java -jar src/yuic.jar --line-break 100 --nomunge --type js -o '#{@qatooljs_compressed}' #{@qatooljs}")
@htmlc=File.read(@html)
@top=@htmlc.split("<!--BREAK1-->")[0]
@bottom=@htmlc.split("<!--BREAK2-->")[1]
@prototype=File.read(@prototypejs)
@livepipe=File.read(@livepipejs)
@swfobject=File.read(@swfobjectjs)
@csscontents=File.read(@maincss_compressed)
@jscontents=File.read(@qatooljs_compressed)
@top<<"<style>\n#{@csscontents}\n</style>\n"
@top<<"<script type='text/javascript'>\n#{@prototype}\n</script>\n"
@top<<"<script type='text/javascript'>\ntry{#{@swfobject}}catch(e){}\n</script>\n"
@top<<"<script type='text/javascript'>\n#{@livepipe}\n</script>\n"
@top<<"<script type='text/javascript'>\n#{@jscontents}\n</script>\n"
@top<<"<script type='text/javascript'>/**SWFINFO**/</script>"
@top<<@bottom
File.open(@finaloutfile,'w') do |f|
  f.puts @top
end