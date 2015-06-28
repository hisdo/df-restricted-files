require_dependency 'enum_site_setting'
class RestrictFiles_AccessListType < EnumSiteSetting
	def self.valid_value?(val)
		val.blank? or values.any? { |v| v[:value] == val.to_s }
	end
	def self.values
		@values ||= [
			{name: 'whitelist', value: 'whitelist'},
			{name: 'blacklist', value: 'blacklist'}
		]
	end
	def self.translate_names?
		true
	end
end