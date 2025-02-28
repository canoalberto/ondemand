# frozen_string_literal: true

require 'test_helper'

class ScriptTest < ActiveSupport::TestCase
  test 'supported field postfix' do
    target = Script.new({ project_dir: '/path/project', id: 1234, title: 'Test Script' })
    refute target.send('attribute_parameter?', nil)
    refute target.send('attribute_parameter?', '')
    refute target.send('attribute_parameter?', 'account_notsupported')
    assert target.send('attribute_parameter?', 'account_min')
    assert target.send('attribute_parameter?', 'account_max')
    assert target.send('attribute_parameter?', 'account_exclude')
    assert target.send('attribute_parameter?', 'account_fixed')
  end

  test 'clusters? return false when auto_batch_clusters returns no clusters' do
    Configuration.stubs(:job_clusters).returns([])

    assert_equal false, Script.clusters?
  end

  test 'clusters? return true when auto_batch_clusters returns clusters' do
    Configuration.stubs(:job_clusters).returns(OodCore::Clusters.load_file('test/fixtures/config/clusters.d'))

    assert_equal true, Script.clusters?
  end

  test 'creates script' do
    Dir.mktmpdir do |tmp|
      projects_path = Pathname.new(tmp)
      OodAppkit.stubs(:dataroot).returns(projects_path)
      target = Script.new({ project_dir: projects_path.to_s, id: 1234, title: 'Test Script' })

      assert target.save
      assert Dir.entries("#{projects_path}/.ondemand/scripts").include?('1234')
    end
  end

  test 'deletes script' do
    Dir.mktmpdir do |tmp|
      projects_path = Pathname.new(tmp)
      OodAppkit.stubs(:dataroot).returns(projects_path)
      target = Script.new({ project_dir: projects_path.to_s, id: 1234, title: 'Test Script' })

      assert target.save
      assert Dir.entries("#{projects_path}/.ondemand/scripts").include?('1234')

      assert target.destroy
      assert_not Dir.entries("#{projects_path}/.ondemand/scripts").include?('1234')
    end
  end

  test 'deletes script should succeed when directory does not exists' do
    Dir.mktmpdir do |tmp|
      projects_path = Pathname.new(tmp)
      OodAppkit.stubs(:dataroot).returns(projects_path)
      script = Script.new({ project_dir: projects_path.to_s, id: 1234, title: 'Test Script' })
      assert script.save
      assert Dir.entries("#{projects_path}/.ondemand/scripts").include?('1234')

      target = Script.new({ project_dir: projects_path.to_s, id: 33, title: 'Not saved' })
      assert_not Dir.entries("#{projects_path}/.ondemand/scripts").include?('33')

      assert target.destroy
      assert Dir.entries("#{projects_path}/.ondemand/scripts").include?('1234')
      assert_not Dir.entries("#{projects_path}/.ondemand/scripts").include?('33')
    end
  end
end
