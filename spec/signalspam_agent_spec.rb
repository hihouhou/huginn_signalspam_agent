require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::SignalspamAgent do
  before(:each) do
    @valid_options = Agents::SignalspamAgent.new.default_options
    @checker = Agents::SignalspamAgent.new(:name => "SignalspamAgent", :options => @valid_options)
    @checker.user = users(:bob)
    @checker.save!
  end

  pending "add specs here"
end
