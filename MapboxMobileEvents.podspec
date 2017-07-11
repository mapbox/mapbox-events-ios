Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.name = 'MapboxMobileEvents'
  s.version = '0.2.3'
  s.summary = 'Mapbox Mobile Events'

  s.description  = 'Collects usage information to help Mapbox improve its products.'

  s.homepage = 'https://www.mapbox.com/'

  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.license = { :type => 'ISC', :file => 'LICENSE.md' }

  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.author = { 'Mapbox' => 'mobile@mapbox.com' }
  s.social_media_url = 'https://twitter.com/mapbox'

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.ios.deployment_target = '8.0'


  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.source = { :git => 'https://github.com/mapbox/mapbox-events-ios.git', :tag => 'v#{s.version.to_s}' }

  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.source_files = ['MapboxMobileEvents/**/*.{h,m}']

  s.resources = 'MapboxMobileEvents/Resources/*'

  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.requires_arc = true
  s.module_name = 'MapboxMobileEvents'

end
