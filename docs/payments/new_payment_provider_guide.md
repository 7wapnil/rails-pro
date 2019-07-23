## How to add new payment provider

1) Select which kind of currency is used for new provider payments (Fiat / Crypto)

2) Add folder below selected kind of currency with the name of your provider. 
**Example:** `payments/fiat/stripe` (`stripe` will be used below as example provider name)

3) Create provider within `stripe` with implemented mandatory deposit/payout methods

    ```ruby
    # payments/fiat/stripe/provider.rb
    
    module Payments
      module Fiat
        module Stripe
          class Provider < ::Payments::Fiat::Provider
            def payment_page_url
              # generate url to be redirected to your provider deposit page.
              # Place implementation in 
              # payments/fiat/stripe/deposits/request_handler.rb
              # and call it here
            end
            
            def payout_request_handler
              # class_name of service which will create an external API request 
              # for payout using your provider.
              # payments/fiat/stripe/payouts/request_handler.rb 
            end
          end
        end
      end
    end
    ```

4) Add your payment method to the general list of methods

    ```ruby
    # payments/methods.rb
    
    module Payments
      module Methods
        CUSTOM = 'custom'
        
        METHOD_PROVIDERS = {
          ...,
          CUSTOM => {
            provider: ::Payments::Fiat::Stripe::Provider,
            name: CUSTOM,
            currency_kind: Currency::FIAT
          }
        }.freeze
      end
    end
    ```

    You can additionally:
    - add explicit currency to your payment method. Usually needed for crypto-currency, to bind it to some kind of currency;
    
    ```ruby
    METHOD_PROVIDERS = {
      ...,
      LITECOIN => {
        provider: ::Payments::Crypto::Litecoin::Provider,
        name: LITECOIN,
        currency_kind: Currency::CRYPTO,
        currency: 'LTC'
      }
    }.freeze
    ```
    
    - add your payment method to the list of methods which are used for withdrawal only in the same condition as they were used for deposit. 
    **Example:** you can select credit card on withdrawal, using which you had performed a deposit before. But you have no possibility to enter new credit card details. 
    
    ```ruby
    CHOSEN_PAYMENT_METHODS = [..., CUSTOM].freeze
    ```
    
    - add your payment method to the list of method which can be re-entered on withdrawal.
    **Example:** you can select a bitcoin method on withdrawal, because you had performed a deposit using bitcoin before. Also, you have a possibility to enter new bitcoin address to perform withdrawal.
    
    ```ruby
    ENTERED_PAYMENT_METHODS = [..., CUSTOM].freeze
    ```

5) Implement `Deposit/Payout` callback handlers

6) Create callback handler, which selects respective callback handler

    ```ruby
    # payments/fiat/stripe/callback_handler.rb
    
    module Payments
      module Fiat
        module Stripe
          class CallbackHandler < ::ApplicationService
            DEPOSIT = 'deposit'
            WITHDRAWAL = 'withdrawal'
    
            def initialize(request)
              @request = request
            end
    
            def call
              callback_handler.call(response)
            end
    
            private
    
            attr_reader :request
    
            def response
              @response ||= JSON.parse(request)
            end
    
            def callback_handler
              case payment_type
              when DEPOSIT
                ::Payments::Fiat::Stripe::Deposits::CallbackHandler
              when WITHDRAWAL
                ::Payments::Fiat::Stripe::Payouts::CallbackHandler
              else
                non_supported_payment_type!
              end
            end
    
            def non_supported_payment_type!
              raise ::Payments::NotSupportedError, 'Non supported payment type'
            end
          end
        end
      end
    end
    ```

7) Add webhook path to `routes.rb`

    ```ruby
    namespace :webhooks do
      ...
   
      namespace :stripe do
        match :payment, to: 'payments#create', via: %i[get post]
      end
    end
    ```

8) Create webhook controller

    ```ruby
    # app/controllers/webhooks/stripe/payments_controller.rb
    
    module Webhooks
      module Stripe
        class PaymentsController < ActionController::Base
          skip_before_action :verify_authenticity_token
          before_action :verify_payment_signature
    
          def create
            ::Payments::Fiat::Stripe::CallbackHandler.call(request)
    
            callback_redirect_for(::Payments::Webhooks::Statuses::SUCCESS)
          rescue ::Payments::CancelledError
            callback_redirect_for(::Payments::Webhooks::Statuses::CANCELLED)
          rescue ::Payments::FailedError
            callback_redirect_for(::Payments::Webhooks::Statuses::FAILED)
          rescue StandardError => error
            Rails.logger.error(message: 'Technical error appeared on deposit',
                               error: error.message)
    
            callback_redirect_for(::Payments::Webhooks::Statuses::SYSTEM_ERROR)
          end
    
          private
    
          def verify_payment_signature
            # compare signature to be sure that webhook has been sent
            # by your provider, but not by a hacker. 
            # On negative result - raise an error
            return if ::Payments::Fiat::Stripe::SignatureVerifier.call(params)
         
            raise ::Deposits::AuthenticationError,
                  'Malformed Stripe deposit request!'
          end
    
          # build redirection url
          def callback_redirect_for(status)
            redirect_to(
              ::Payments::Webhooks::DepositRedirectionUrlBuilder
                .call(status: status)
            )
          end
        end
      end
    end
    ```

9) Add your method type to GraphQL payment methods and mention it in `docs` guides.
    ```ruby
    # app/graphql/payments/methods/custom_type.rb
 
    # frozen_string_literal: true
    
    module Payments
      module Methods
        CustomType = GraphQL::ObjectType.define do
          name 'PaymentMethodCustom'
    
          # mandatory
          field :id, !types.ID
       
          # mandatory
          field :title, !types.String,
                resolve: ->(*) { ::Payments::Methods::BITCOIN.humanize } 
             
          # optional, to add possibility to manually enter details on withdrawal 
          field :isEditable, !types.Boolean, resolve: ->(*) { true }
       
          # your payment method fields
          field :field1, !types.String
          field :field2, !types.String
        end
      end
    end 
    ```
    - [Guide Link 1](https://github.com/arcanebet/backend/blob/master/docs/payments/methods.md)
    
    - [Guide Link 2](https://github.com/arcanebet/backend/blob/master/docs/payments/graphql/methods.md)

10) Create form object to validate your payment method details.

    ```ruby
    # app/forms/payments/withdrawals/methods/custom_form.rb
 
    class CustomForm < WithdrawalMethodForm
      attr_accessor :field_1, :field_2

      validates :field_1, :field_2, presence: true
  
      # only if your currency kind is FIAT
      
      def identifier
        :field_1 # name of field which identifies payment details
      end

      def consistency_error_message
        # error message for payment details inconsistency
  
        # Example: you deposited with one payment method, but withdrawal
        # payment details were changed by Javascript 
      end 
    end
    ```

11) Teach withdrawal form to validate your payment method details.
    ```ruby
    # app/forms/payments/withdrawals/create_form.rb
    
    class CreateForm
        ...
        
        def payment_method_form_class
          case payment_method
          ...
          when CUSTOM then Payments::Withdrawals::Methods::CustomForm
          end
        end
    end
    ``` 

12) Fill needed text content in `config/locales/en.yml` under `payments` namespace.

13) You're a rockstar!
