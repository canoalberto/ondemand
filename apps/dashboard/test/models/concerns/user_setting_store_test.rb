# frozen_string_literal: true

require 'test_helper'

class UserSettingStoreTest < ActionView::TestCase
  include UserSettingStore

  def setup
    @user_settings = nil
  end

  test 'user_settings cannot be modified' do
    current_settings = user_settings
    current_settings[:profile] = 'new value'

    refute_equal current_settings, user_settings
    refute_equal current_settings[:profile], user_settings[:profile]
  end

  test 'read_user_settings should read data from user settings file' do
    with_modified_env(OOD_DATAROOT:           "#{Rails.root}/test/fixtures/config/user_settings",
                      OOD_USER_SETTINGS_FILE: '.valid') do
      expected_user_settings = { :profile=>'file_value' }

      assert_equal expected_user_settings, read_user_settings
    end
  end

  test 'read_user_settings should log errors when reading settings from file' do
    with_modified_env(OOD_DATAROOT:           "#{Rails.root}/test/fixtures/config/user_settings",
                      OOD_USER_SETTINGS_FILE: '.invalid') do
      Rails.logger.expects(:error).with(regexp_matches(/Can't read or parse settings file/)).at_least_once
      expected_user_settings = {}

      assert_equal expected_user_settings, read_user_settings
    end
  end

  test 'update_user_settings should create data directory when is not available' do
    Dir.mktmpdir do |temp_data_dir|
      data_root = Pathname.new(temp_data_dir).join('update_test')
      assert_equal false, data_root.exist?

      Configuration.stubs(:dataroot).returns(data_root.to_s)

      update_user_settings({})

      assert_equal true, data_root.exist?
    end
  end

  test 'update_user_settings should update internal data and user settings file' do
    Dir.mktmpdir do |temp_data_dir|
      Configuration.stubs(:dataroot).returns(temp_data_dir)

      settings = user_settings
      settings[:profile] = 'profile_value'
      update_user_settings(settings)

      assert_equal settings, user_settings
      assert_equal settings, YAML.safe_load(File.read(user_settings_path)).deep_symbolize_keys
    end
  end

end
