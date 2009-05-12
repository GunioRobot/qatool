#!/usr/bin/env ruby
require "rubygems"
require "fileutils"
require "roo"
require "swfheader"
require "optparse"

#setup optparse
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
  opts.on("-b", "--list-backup-bitmaps", "Whether or not to list jpg, jpeg and gif files in the files list in the qatool.") do |s|
    OPTIONS[:listBackupBitmaps]=s if s != nil
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

#method and class definitions / updates
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

#check for spec xls sheet
if File.exists?("specs.xlsx") then OPTIONS[:spec]="specs.xlsx" end
if File.exists?("specs.xls") then OPTIONS[:spec]="specs.xls" end
if not OPTIONS[:spec]
  if OPTIONS[:spec_only] then puts "WARNING: Spec sheet not found, nothing to do."
  else puts "WARNING: Spec sheet not found, summary will be generated, but meta data cannot be verified." end
  OPTIONS[:spec_404]=true
end

fs="/"
bs="\\"
fsr=/\//
bsr=/\\/
swfr=/\.swf/
jpgr=/\.jpg/
jpegr=/\.jpeg/
gifr=/\.gif/
error_output=""
templates_path=""
qatool_template=""
error_template=""
preview_template=""
file_meta_by_file={}
specs_by_file={}
files=[]
swfs=Dir.glob(File.join("**","*.swf"))
jpgs=Dir.glob(File.join("**","*.jpg"))
gifs=Dir.glob(File.join("**","*.gif"))
jpegs=Dir.glob(File.join("**","*.jpeg"))
if swfs.length>0
  files<<swfs
  swfs.each do |file|
    meta={}
    header=SwfUtil::read_header(file)
    meta[:type]="swf"
    meta[:version]=header.version
    meta[:size]=header.size/1024
    meta[:width]=header.width
    meta[:height]=header.height
    meta[:frame_rate]=header.frame_rate
    meta[:frame_count]=header.frame_count
    file_meta_by_file[file]=meta
  end
end
if jpgs.length>0
  files<<jpgs
  jpgs.each do |file|
    size=File.size(file)/1024
    type="bitmap"
    file_meta_by_file[file]={:size=>size,:type=>type}
  end
end
if gifs.length>0
  files<<gifs
  gifs.each do |file|
    size=File.size(file)/1024
    type="bitmap"
    file_meta_by_file[file]={:size=>size,:type=>type}
  end
end
if jpegs.length>0
  files<<jpegs
  jpegs.each do |file|
    size=File.size(file)/1024
    type="bitmap"
    file_meta_by_file[file]={:size=>size,:type=>type}
  end
end
files.flatten!
files.sort!
if swfs.length < 1 and jpgs.length < 1 and gifs.length < 1 and jpegs.length <1
  puts "No files, nothing to do."
  exit(0)
end

#find templates
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

FileUtils.rm_rf("__summary.html")
if OPTIONS[:spec] and not OPTIONS[:spec_404]
  if OPTIONS[:spec].match(/\.xlsx/) then e=Excelx.new(OPTIONS[:spec])
  else e=Excel.new(OPTIONS[:spec]) end
  sheet=1;row=1
  if e.sheets && e.sheets.length>1
    e.default_sheet=e.sheets[1]
    if not e.cell(2,"A").to_s.match(swfr)
      puts "The spec sheet does not appear to be the correct format. A summary will be generated, but it will not be against a spec sheet."
      OPTIONS[:spec_404]=true
    end
  elsif e.sheets && e.sheets.length<2
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
          if file.match(swfr)
            obj={
                :file=>file,:version=>e.cell(row,"B"),:frame_rate=>e.cell(row,"C"),:width=>(e.cell(row,"D").split("x")[0]),
                :height=>(e.cell(row,"D").split("x")[1]),:size=>e.cell(row,"E"),:seconds=>e.cell(row,"F"),:click=>e.cell(row,"G"),:clickTag=>e.cell(row,"H"),
                :previewTitle=>(e.cell(row,"I"))
            }
          elsif file.match(/(\.gif)|(\.jpg)/)
            obj={:file=>file,:size=>e.cell(row,"E")}
          end
          specs_by_file[file]=obj
        else
          break
        end
        row+=1
      end
    end
  end
end

error_output<<"<tr class='metaInfo'>"
if files.length == 0 then no_swfs end
files.each do |file|
  file_meta=file_meta_by_file[file]
  spec_meta=specs_by_file[file]
  if not file_meta then next end
  if not spec_meta
    if file_meta[:type]=="swf"
      error_output << "<td class='noSpecSheetEntry'>#{file}</td>"
      error_output << "<td>#{file_meta[:version]}</td>"
      error_output << "<td>#{file_meta[:frame_rate]}</td>"
      error_output << "<td>#{file_meta[:width]}</td>"
      error_output << "<td>#{file_meta[:height]}</td>"
      error_output << "<td>#{file_meta[:size]}</td>"
      error_output << "</tr>"
    elsif file_meta[:type]=="bitmap"
      error_output << "<td class='noSpecSheetEntry'>#{file}</td>"
      error_output << "<td>N/A</td>"
      error_output << "<td>N/A</td>"
      error_output << "<td>N/A</td>"
      error_output << "<td>N/A</td>"
      error_output << "<td>#{file_meta[:size]}K</td>"
      error_output << "</tr>"
    end
  else
    if file_meta[:type]=="swf"
      error_output<<"<td>#{file}</td>"
      if file_meta[:version].to_i != spec_meta[:version] then error_output<<"<td class='error'>expected: #{spec_meta[:version].to_i} actual: #{file_meta[:version]}</td>"
      else error_output << "<td>#{file_meta[:version]}</td>" end
      if file_meta[:frame_rate] != spec_meta[:frame_rate] then error_output << "<td class='error'>expected: #{spec_meta[:frame_rate].to_i} actual: #{file_meta[:frame_rate]}</td>"
      else error_output << "<td>#{file_meta[:frame_rate]}</td>" end
      if file_meta[:width].to_i != spec_meta[:width] then error_output << "<td class='error'>expected: #{spec_meta[:width].to_i} actual: #{file_meta[:width]}</td>"
      else error_output << "<td>#{file_meta[:width]}</td>" end
      if file_meta[:height].to_i != spec_meta[:height] then error_output<<"<td class='error'>expected: #{spec_meta[:height].to_i} actual: #{file_meta[:height]}</td>"
      else error_output << "<td>#{file_meta[:height]}</td>" end
      if file_meta[:size] > spec_meta[:size].to_f then error_output << "<td class='error'>expected: #{spec_meta[:size].to_f} actual: #{file_meta[:size]}K</td>"
      else error_output << "<td>#{file_meta[:size]}</td>" end
      error_output<<"</tr>"
    elsif file_meta[:type]=="bitmap"
      error_output << "<td>#{file}</td>"
      error_output << "<td>N/A</td>"
      error_output << "<td>N/A</td>"
      error_output << "<td>N/A</td>"
      error_output << "<td>N/A</td>"
      if file_meta[:size]>spec_meta[:size] then error_output << "<td class='error'>expected: #{spec_meta[:size]} actual: #{file_meta[:size]}K</td>"
      else error_output << "<td>#{file_meta[:size]}K</td>" end
      error_output<<"</tr>"
    end
  end
end

error_template_contents.sub!(/\<\!\-\-\*\*ERRORS\*\*\-\-\>/,error_output)
File.write("__summary.html",error_template_contents)
if OPTIONS[:spec_only] then exit(0) end

qatool_template_contents=File.read(qatool_template)
preview_contents=File.read(preview_template)

#find backup bitmaps for swfs
backup_bitmaps={}
swfs.each do |swf|
  jpg=swf.dup.sub(swfr,".jpg")
  gif=swf.dup.sub(swfr,".gif")
  jpeg=swf.dup.sub(swfr,".jpeg")
  if File.exists?(jpg) then backup_bitmaps[swf]=jpg end
  if File.exists?(gif) then backup_bitmaps[swf]=gif end
  if File.exists?(jpeg) then backup_bitmaps[swf]=jpeg end
end

js="var swfInfo=[" #js swf info
qatool_files=files
if OPTIONS[:listBackupBitmaps] then qatool_files=files
else qatool_files=swfs end
qatool_files.each do |file|
  meta=file_meta_by_file[file]
  t="{file:'#{file}',name:'#{file}',hash:'#{rand_uuid}',type:'#{meta[:type]}'"
  spec_meta=specs_by_file[file]
  if spec_meta
    if OPTIONS[:autoClickTags]
      if spec_meta[:click] and spec_meta[:clickTag] then t << ",customClickTag:'#{spec_meta[:clickTag]}',customClickTagValue:'#{spec_meta[:click]}'" end
    end
    if spec_meta[:previewTitle] then t << ",previewTitle:'#{spec_meta[:previewTitle]}'" end
  end
  if backup_bitmaps[file] then t<<",backupBitmap:'#{backup_bitmaps[file]}'" end
  meta="meta:{width:'#{meta[:width]}',height:'#{meta[:height]}',version:'#{meta[:version]}',size:'#{meta[:size]}'}"
  t<<",#{meta}},"
  js<<t
end
js.sub!(/\,$/,"")
js<<"];"

qatool_template_contents.sub!(/\/\*\*SWFINFO\*\*\//,js)
preview_contents.sub!(/\/\*\*SWFINFO\*\*\//,js)
File.rm_rf_then_write("__qatool.html",qatool_template_contents)
File.rm_rf_then_write("__preview.html",preview_contents)