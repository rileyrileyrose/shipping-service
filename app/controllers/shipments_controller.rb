class ShipmentsController < ApplicationController
  def shipment
    if !params.include?("destination") || !params.include?("origin") || !params.include?("packages")
      render:json => ["You didn't submit the correct information."].as_json, :status => :bad_request
    else
      origin = ActiveShipping::Location.new(country: 'US', state: 'CA', city: 'Beverly Hills', zip: '90210')

      destination = ActiveShipping::Location.new(country: params[:destination][:country], state: params[:destination][:state], city: params[:destination][:city], zip: params[:destination][:zip])
      packages = []
      if !params[:packages].nil?
        params[:packages].each do |package|
          weight = package[:weight].to_i
          dimensions = package[:dimensions].to_a.map! { |num| num.to_i }

          pack = ActiveShipping::Package.new(weight, dimensions)
          packages << pack
        end
          @quotes = get_quotes(origin, destination, packages)
          render :json => @quotes.as_json
      else
        render:json => ["Packages is empty"].as_json, :status => :bad_request
      end
    end
  end

  private

  def get_quotes(origin, destination, packages)
    quotes = []

    ups = ActiveShipping::UPS.new(login: ENV["UPS_LOGIN"], password: ENV["UPS_PASSWORD"], key: ENV["UPS_KEY"])
    response = ups.find_rates(origin, destination, packages)
    ups_rates = response.rates.sort_by(&:price).collect {|rate| [rate.service_name, rate.price]}

    usps = ActiveShipping::USPS.new(login: ENV["ACTIVESHIPPING_USPS_LOGIN"])

    response = usps.find_rates(origin, destination, packages)
    usps_rates = response.rates.sort_by(&:price).collect {|rate| [rate.service_name, rate.price ]}

    quotes << ups_rates
    quotes << usps_rates
    return quotes
  end

end
