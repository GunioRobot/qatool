#!/usr/bin/env ruby
require "rubygems"
require "fileutils"
require "roo"
require "swfheader"
require "optparse"

OPTIONS={}
OPTIONS[:run]=true
OPTIONS[:spec]=nil
opts=OptionParser.new do |opts|
  opts.on("-x", "--spec-only", "Check that swfs match a specsheet, and only generate the summary page.") do |s|
    OPTIONS[:spec_only]=s if s != nil
  end
  opts.on("-a", "--auto-clicktags", "Automatically map the click tag destination, and click tag type from a specsheet, as the default click tag to the banners in the qatool.") do |s|
    OPTIONS[:autoClickTags]=s if s != nil
  end
  opts.on_tail("-h", "--help", "Show this usage statement.") do |h|
    puts opts
    OPTIONS[:run]=false
  end
end
begin
  opts.parse!(ARGV)
rescue Exception => e
  puts e, "", opts
  exit
end
if not OPTIONS[:run] then exit(0) end

def rand_uuid
  [8,4,4,4,12].map {|n| rand_hex_3(n)}.join('-').to_s
end
def rand_hex_3(l)
  "%0#{l}x" % rand(1 << l*4)
end
def warn_duplicate
  if OPTIONS[:spec] and not OPTIONS[:spec_404] and not OPTIONS[:warned_about_duplicate]  
    puts "WARNING: Duplicate file in different directories found, you cannot have a duplicate swf, jpg, or gif in different directories. This will effect accuracy of summary generation."
    OPTIONS[:warned_about_duplicate]=true
  end
end
def no_swfs
  puts "No swfs found, nothing to do."
  exit
end
class Float
  alias_method :round_orig, :round
  def round(n=0)
    (self * (10.0 ** n)).round_orig * (10.0 ** (-n))
  end
end
class File
  def self.write(filename,contents)
    File.open(filename,"w") do |f|
      f.puts contents
    end
  end
  def self.rm_rf_then_write(filename,contents)
    FileUtils.rm_rf(filename)
    File.write(filename,contents)
  end
end

swfs=Dir.glob(File.join("**","*.swf"))
if not swfs or swfs.length < 1
  puts "No swfs, nothing to do."
  exit(0)
end

if File.exists?("specs.xlsx") then OPTIONS[:spec]="specs.xlsx" end
if File.exists?("specs.xls") then OPTIONS[:spec]="specs.xls" end
if not OPTIONS[:spec]
  if OPTIONS[:spec_only] then puts "WARNING: Spec sheet not found, nothing to do."
  else puts "WARNING: Spec sheet not found, no summary will be generated." end
  OPTIONS[:spec_404]=true
end

fs="/"
bs="\\"
fsr=/\//
bsr=/\\/
swfr=/\.swf/
backupbitmaps={}
filenameLookup={}
swf_meta_by_swf={}
swf_meta_by_short_swf_name={}
swf_sizes_by_swf={}
backupbitmap_sizes_by_swf={}
error_output=""
templates_path=""
qatool_template=""
error_template=""
preview_template=""
excelcvt=""
df=Gem.default_path
df.each do |p|
  d=Dir.glob(p+"/gems/qatool**/lib/*")
  if d.length > 0 then templates_path=d end
end
if !templates_path
  puts "Templates could not be found, please contact aaron.smith@mccannsf.com"
  exit(0)
end
templates_path.each do |t|
  if t.match(/qatool.html$/) then qatool_template=t end
  if t.match(/summary.html$/) then error_template=t end
  if t.match(/previewpage.html$/) then preview_template=t end
end
error_template_contents=File.read(error_template)

swfs.each do |swf| #backup bitmap discovery and swf meta discovery
  jpg=swf.sub(swfr,".jpg")
  gif=swf.sub(swfr,".gif")
  jpgExist=File.exists?(jpg)
  gifExist=File.exists?(gif)
  if jpgExist then backupbitmaps[swf]=jpg
  elsif gifExist then backupbitmaps[swf]=gif end
  if backupbitmaps[swf] then backupbitmap_sizes_by_swf[swf]=File.read(backupbitmaps[swf]).length end
  swf_sizes_by_swf[swf]=File.size(swf)
  swf_meta_by_swf[swf]=SwfUtil::read_header(swf)
  
  if swf.match(fsr) then name=swf.split(fs)[-1]
  elsif swf.match(bsr) then name=swf.split(bs)[-1]
  else name=swf end
  swf_meta_by_short_swf_name[name]=swf_meta_by_swf[swf]
  
  if not OPTIONS[:spec_404]  
    if filenameLookup[name] then warn_duplicate end
    filenameLookup[name]=swf
    if jpgExist then bmp=jpg end
    if gifExist then bmp=gif end
    if bmp and bmp.match(bsr) then bmpName=bmp.split(fs)[-1]
    elsif bmp and bmp.match(bsr) then bmpName=bmp.split(bs)[-1] end
    if bmpName then filenameLookup[bmpName]=bmp end
  end
end

FileUtils.rm_rf("__summary.html")
if OPTIONS[:spec] and not OPTIONS[:spec_404]
  if OPTIONS[:spec].match(/\.xlsx/) then e=Excelx.new(OPTIONS[:spec])
  else e=Excel.new(OPTIONS[:spec]) end
  sheet=1;row=1
  summary_swfs=[]
  summary_swfsByFile={}
  summary_bmps=[]
  summary_bmpsByFile={}
  if e.sheets && e.sheets.length > 1
    e.default_sheet = e.sheets[1]
    if not e.cell(2,"A").to_s.match(/\.swf/)
      puts "The spec sheet does not appear to be the correct format. A summary will be generated, but it will not be against a spec sheet."
      OPTIONS[:spec_404]=true
    end
  elsif e.sheets && e.sheets.length < 2
    puts "The spec sheet does not appear to be the correct format. A summary will be generated, but it will not be against a spec sheet."
    OPTIONS[:spec_404]=true
  end
  if not OPTIONS[:spec_404]
    e.sheets.each do |s|
      if sheet == 1 then sheet += 1; next end
      e.default_sheet=s
      row=2
      while true
        if e.cell(row,"A")
          file=e.cell(row,"A")
          if not file.match(/\.swf/) then next end
          if file.match(/\.swf/)
            obj = {
                :file=>e.cell(row,'A'),:version=>e.cell(row,"B"),:fps=>e.cell(row,"C"),:width=>(e.cell(row,"D").split("x")[0]),
                :height=>(e.cell(row,"D").split("x")[1]),:size=>e.cell(row,"E"),:seconds=>e.cell(row,"F"),:click=>e.cell(row,"G"),:clickTag=>e.cell(row,"H"),
                :previewTitle=>(e.cell(row,"I"))
            }
            summary_swfs.push(obj)
            summary_swfsByFile[file]=obj
          elsif file.match(/\.gif|\.jpg/)
            obj = {
                :file=>e.cell(row,'A'),:width=>(e.cell(row,"D").split("x")[0]),:height=>(e.cell(row,"D").split("x")[1]),:size=>e.cell(row,"E"),
                :seconds=>e.cell(row,"F"),:click=>e.cell(row,"G"),:clickTag=>e.cell(row,"H")
            }
            summary_bmpsByFile[file]=obj
            summary_bmps.push(obj)
          end
        else
          break
        end
        row+=1
      end
    end
    error_output<<"<tr class='metaInfo'>"
    if swfs.length == 0 then no_swfs end
    summary_swfs.each do |ss|
      file=ss[:file]
      longFile=filenameLookup[file]
      meta=swf_meta_by_swf[longFile]
      if meta==nil then next end
      swfsize=(swf_sizes_by_swf[longFile].to_f/1024).round(2)
      error_output<<"<td>#{file}</td>"
      if ss[:version].to_i != meta.version then error_output<<"<td class='error'>expected: #{ss[:version].to_i} actual: #{meta.version}</td>"
      else error_output << "<td>#{meta.version}</td>" end
      if ss[:fps]!=meta.frame_rate then error_output << "<td class='error'>expected: #{ss[:fps].to_i} actual: #{meta.frame_rate}</td>"
      else error_output << "<td>#{meta.frame_rate}</td>" end
      if ss[:width].to_i!=meta.width then error_output << "<td class='error'>expected: #{ss[:width].to_i} actual: #{meta.width}</td>"
      else error_output << "<td>#{meta.width}</td>" end  
      if ss[:height].to_i!=meta.height then error_output<<"<td class='error'>expected: #{ss[:height].to_i} actual: #{meta.height}</td>"
      else error_output << "<td>#{meta.height}</td>" end
      if swfsize>(ss[:size]).to_f then error_output << "<td class='error'>expected: #{(ss[:size]).to_f} actual: #{swfsize}</td>"
      else error_output << "<td>#{swfsize}</td>" end
      error_output<<"</tr>"
    end
    error_template_contents.sub!(/\<\!\-\-\*\*ERRORS\*\*\-\-\>/,error_output)
    File.write("__summary.html",error_template_contents)
  end
end
if OPTIONS[:spec_404]
  error_output<<"<tr class='metaInfo'>"
  swf_meta_by_short_swf_name.each do |key, value|
    file=key
    meta=swf_meta_by_short_swf_name[file]
    if meta==nil then next end
    swfsize=(swf_sizes_by_swf[file].to_f/1024).round(2)
    error_output<<"<td>#{file}</td>"
    error_output << "<td>#{meta.version}</td>"
    error_output << "<td>#{meta.frame_rate}</td>"
    error_output << "<td>#{meta.width}</td>"
    error_output << "<td>#{meta.height}</td>"
    error_output << "<td>#{swfsize}</td>"
    error_output<<"</tr>"
  end
  error_template_contents.sub!(/\<\!\-\-\*\*ERRORS\*\*\-\-\>/,error_output)
  File.write("__summary.html",error_template_contents)
end
if OPTIONS[:spec_only] then exit(0) end

qatool_template_contents=File.read(qatool_template)
preview_contents=File.read(preview_template)

js="var swfInfo=[" #js swf info
swfs.each do |swf|
  if swf.match(fsr) then name=swf.split(fs)[-1]
  elsif swf.match(bsr) then name=swf.split(bs)[-1]
  else name=swf end
  t="{file:'#{swf}',name:'#{swf}',hash:'#{rand_uuid}'"
  if summary_swfsByFile
    edata=summary_swfsByFile[name]
    if edata
      if OPTIONS[:autoClickTags]
        if edata[:click] and edata[:clickTag] then t << ",customClickTag:'#{edata[:clickTag]}',customClickTagValue:'#{edata[:click]}'" end
      end
      if edata[:previewTitle] then t << ",previewTitle:'#{edata[:previewTitle]}'" end
    end
  end
  if backupbitmaps[swf] then t<<",backupBitmap:'#{backupbitmaps[swf]}'" end
  meta="meta:{width:'#{swf_meta_by_swf[swf].width}',height:'#{swf_meta_by_swf[swf].height}',version:'#{swf_meta_by_swf[swf].version}',size:'#{swf_sizes_by_swf[swf]}'}"
  t<<",#{meta}},"
  js<<t
end
js.sub!(/\,$/,"")
js<<"];"

qatool_template_contents.sub!(/\/\*\*SWFINFO\*\*\//,js)
preview_contents.sub!(/\/\*\*SWFINFO\*\*\//,js)
File.rm_rf_then_write("__qatool.html",qatool_template_contents)
File.rm_rf_then_write("__preview.html",preview_contents)