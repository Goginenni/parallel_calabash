require 'spec_helper'

require 'parallel_appium/adb_helper'
describe ParallelAppium::AdbHelper do

  describe :device_id_and_model do
    it 'should not match any devices in list of devices attached line' do
      expect(ParallelAppium::AdbHelper.device_id_and_model("List of devices attached")).to eq nil
    end

    it 'should match devices if there is a space after the word device' do
       expect(ParallelAppium::AdbHelper.device_id_and_model("emulator-5554  device ")).to eq \
         ["emulator-5554", nil]
    end

    it 'should match devices if there is not a space after the word device' do
      expect(ParallelAppium::AdbHelper.device_id_and_model("emulator-5554  device")).to eq \
         ["emulator-5554", nil]
    end

    it 'should not match a device if it is an empty line' do
      expect(ParallelAppium::AdbHelper.device_id_and_model("")).to eq nil
    end

    it 'should match physical devices' do
      output = "192.168.56.101:5555 device product:vbox86p model:device1 device:vbox86p"
      expect(ParallelAppium::AdbHelper.device_id_and_model(output)).to eq ["192.168.56.101:5555", "device1"]
    end
  end
end
