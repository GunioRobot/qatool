mkdir bin
mkdir -p src/bin
mkdir lib
cp src/summary.html lib/summary.html
ruby scripts/build_previewpage_template.rb
ruby scripts/build_qatool_template.rb
cp src/qatool.rb bin/qatool
rake
sudo gem install pkg/qatool*.gem
cp -r pkg/* pkg_archive
if [ "$1" = "1" ]
then
  cp xls/specs.xlsx test/specs.xlsx
  cd test
  qatool -a
  cd ../
fi
if [ "$2" = "1" ]
then
  mkdir spec_example
  cp xls/specs.xlsx spec_example/
  zip -r site/spec_example.zip spec_example
  rm -rf spec_example
  cp -r test qatool_example
  cp xls/specs.xlsx qatool_example/specs.xlsx
  zip -r site/qatool_example.zip qatool_example > /dev/null
  rm -rf qatool_example
  cp -r test site/preview
fi