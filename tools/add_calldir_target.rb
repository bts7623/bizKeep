# Call Directory Extension 타겟을 Runner.xcodeproj 에 추가 (멱등). 실행:
#   P=/opt/homebrew/Cellar/cocoapods/1.17.0_1/libexec; GEM_PATH="$P:$(gem env gempath)" ruby tools/add_calldir_target.rb
require 'xcodeproj'

proj_path = File.expand_path('../ios/Runner.xcodeproj', __dir__)
proj = Xcodeproj::Project.open(proj_path)
TEAM = '335X4N7849'
EXT_NAME = 'CallDirectory'
EXT_BUNDLE = 'com.bts.bizkeep.calldir'

runner = proj.targets.find { |t| t.name == 'Runner' }
raise 'Runner target not found' unless runner

# 1) Runner 에 entitlements 연결 (App Group)
runner.build_configurations.each do |c|
  c.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
end
runner_group = proj.main_group.find_subpath('Runner', false) || proj.main_group
unless runner_group.files.any? { |f| f.path == 'Runner.entitlements' }
  runner_group.new_file('Runner/Runner.entitlements').tap { |r| r.set_path('Runner.entitlements') }
end
unless runner_group.files.any? { |f| f.path == 'CallDirPlugin.swift' }
  ref = runner_group.new_file('CallDirPlugin.swift')
  runner.source_build_phase.add_file_reference(ref)
end

# 2) 익스텐션 타겟
ext = proj.targets.find { |t| t.name == EXT_NAME }
unless ext
  ext = proj.new_target(:app_extension, EXT_NAME, :ios, '15.5')
  grp = proj.main_group.new_group(EXT_NAME, EXT_NAME)
  src = grp.new_file('CallDirectoryHandler.swift')
  grp.new_file('Info.plist')
  grp.new_file('CallDirectory.entitlements')
  ext.source_build_phase.add_file_reference(src)
  ext.add_system_framework('CallKit')
  # Runner 가 익스텐션을 임베드
  runner.add_dependency(ext)
  embed = runner.build_phases.find { |p| p.respond_to?(:name) && p.name == 'Embed Foundation Extensions' } ||
          runner.new_copy_files_build_phase('Embed Foundation Extensions').tap { |p| p.symbol_dst_subfolder_spec = :plug_ins }
  unless embed.files_references.include?(ext.product_reference)
    bf = embed.add_file_reference(ext.product_reference)
    bf.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
  end
end
ext.product_reference.path = "#{EXT_NAME}.appex" if ext.product_reference && ext.product_reference.path.to_s !~ /#{EXT_NAME}/
ext.product_reference.name = "#{EXT_NAME}.appex" if ext.product_reference
ext.build_configurations.each do |c|
  s = c.build_settings
  s['PRODUCT_NAME'] = EXT_NAME
  s['PRODUCT_BUNDLE_IDENTIFIER'] = EXT_BUNDLE
  s['INFOPLIST_FILE'] = "#{EXT_NAME}/Info.plist"
  s['CODE_SIGN_ENTITLEMENTS'] = "#{EXT_NAME}/CallDirectory.entitlements"
  s['CODE_SIGN_STYLE'] = 'Automatic'
  s['DEVELOPMENT_TEAM'] = TEAM
  s['SWIFT_VERSION'] = '5.0'
  s['IPHONEOS_DEPLOYMENT_TARGET'] = '15.5'
  s['TARGETED_DEVICE_FAMILY'] = '1,2'
  s['SKIP_INSTALL'] = 'YES'
  s['GENERATE_INFOPLIST_FILE'] = 'NO'
  s['MARKETING_VERSION'] = '1.0.0'
  s['CURRENT_PROJECT_VERSION'] = '1'
  s['APPLICATION_EXTENSION_API_ONLY'] = 'YES'
  s['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks', '@executable_path/../../Frameworks']
  s['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
end
# 주의: Flutter/Pods xcconfig 는 상속하지 않는다 (익스텐션에 Flutter 프레임워크가 링크되면 안 됨)

# 임베드 단계가 Flutter 의 "Thin Binary" 스크립트보다 먼저 오도록 (뒤에 있으면 빌드 사이클 오류)
embed = runner.build_phases.find { |p| p.respond_to?(:name) && p.name == 'Embed Foundation Extensions' }
thin = runner.build_phases.find { |p| p.isa == 'PBXShellScriptBuildPhase' && p.name.to_s =~ /Thin Binary/ }
if embed && thin
  ei = runner.build_phases.index(embed); ti = runner.build_phases.index(thin)
  runner.build_phases.move(embed, ti) if ei > ti
end

proj.save
puts "ok: targets=#{proj.targets.map(&:name).join(',')}"
