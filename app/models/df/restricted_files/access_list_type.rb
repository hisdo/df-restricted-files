module ::Df::RestrictedFiles
	require_dependency 'enum_site_setting'
	class AccessListType < EnumSiteSetting
		def self.valid_value?(val)
			val.blank? or values.any? { |v| v[:value] == val.to_s }
		end
		def self.values
			@values ||= [
				{name: 'df.restricted_files.acl_type.whitelist', value: 'whitelist'},
				{name: 'df.restricted_files.acl_type.blacklist', value: 'blacklist'}
			]
		end
		def self.translate_names?
			true
		end
	end
end
