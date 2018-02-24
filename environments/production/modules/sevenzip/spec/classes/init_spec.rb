require 'spec_helper'
describe 'sevenzip' do

  context 'with defaults for all parameters' do
    it { should contain_class('sevenzip') }
  end
end
