require 'spec_helper'
require 'cocor'

describe Ruco do
  it 'Has a version number' do
    expect(Ruco::VERSION).not_to be nil
  end

  it 'Extension can be called' do
    expect(Cocor.runtest("meow")).to eq("test-meow")
  end
end
