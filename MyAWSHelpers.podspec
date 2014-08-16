Pod::Spec.new do |spec|
    
	spec.name		= 'MyAWSHelpers'
	spec.version	= '0.2.2'
	spec.homepage   = "http://github.com/premosystems/MyAWSHelpers"
	spec.author     = { "Vincil Bishop" => "vincil.bishop@vbishop.com" }
	spec.license	= 'MIT'
	spec.summary	= 'A collection of often used but time consuming to recreate logic for AWS.'
	spec.source	= { :git => 'https://github.com/premosystems/MyAWSHelpers.git', :tag => spec.version.to_s }
	spec.requires_arc = true
    
	spec.ios.deployment_target = '7.0'
    
	spec.resource = 'MyAWSHelpers.podspec'
    
	spec.source_files = 'MyAWSHelpers/*.{h,m}'

	spec.subspec "S3" do |s3|
        	s3.source_files = 'MyAWSHelpers/S3/*.{h,m}'
        	s3.ios.dependency 'AWSiOSSDK/S3', '~>1.7.1'
        	s3.ios.dependency 'MyiOSHelpers/Logic/ThirdPartyHelpers/CocoaLumberjack', '~>1.0.0'
        	s3.ios.dependency 'MyiOSHelpers/Logic/Blocks', '~>1.0.0'
    end
end