import React, { Component } from 'react';
import Product from './Product';
import CustomerFormModal from './CustomerFormModal';
import ChatUtils from '../../classes/ChatUtils';
import _ from 'lodash';

class Cart extends Component {
  constructor(props) {
    super(props);
    this.state = {
			products: [],
			shipmentMethods: [],
			sum: 0,
			priceWithoutTaxes: 0,
			taxes: 0,
			currency: this.props.contaktiChat.currency,
			showModal: false,
			showCustomerFormModal: false,
			selectedProduct: {},
			selectedShipmentMethod: this.props.contaktiChat.shipment_methods[0],
			selectedCheckoutMethod: this.props.contaktiChat.checkout_methods[0],
		};
  }
  componentDidMount() {
    this.countTotalPricesAndTaxes();
    let { contaktiChat } = this.props;
  }
  handleCustomerFormModalClose = () => {
    this.setState({ showCustomerFormModal: false });
  };
  handleCustomerFormModalShow = () => {
    this.setState({ showCustomerFormModal: true });
  }

  setPluginDisabledState = (disabled) => {
    this.props.setPluginDisabledState( disabled );
    this.setState( { disableChatboxContent: disabled });
  }

  onProductRemove = (product) => {
    let { products } = this.state;
    products = _.reject(products, (p) => {
      return p.id === product.id;
    });
    this.setState({ products }, () => {
      if (this.state.products.length === 0) {
        this.props.onCartEmpty();
      }
      this.countTotalPricesAndTaxes();
    });

  }

  addProduct = (p) => {
    let { products } = this.state;
    var product = _.find(products, { id: p.id });
    if (product) {
      product.quantity += 1;
      this.replaceProduct(product);
    }
    else {
      p.quantity = 1;
      products.push(p)
      this.setState({ products }, () => this.countTotalPricesAndTaxes());

    }
  }


  countTotalPricesAndTaxes = async () => {
		let priceWithoutTaxes = 0, taxes = 0;
    let { products } = this.state;
		_.each( products, ( product ) => {
			const QUANTITY = product.quantity

			taxes += product.tax_amount * QUANTITY;
			priceWithoutTaxes += product.actual_price * QUANTITY
		} );
    await this.setState( { priceWithoutTaxes, taxes } );
		this.calculateSum();
  }

  replaceProduct = (product) => {
    let { products } = this.state;
    var index = _.findIndex(products, { id: product.id });
    products.splice(index, 1, product);
    this.setState({ products });
    this.countTotalPricesAndTaxes();
	}

	handleShipmentChange = async (event) => {
		let selectedId = event.target.value;
		let selected_method = this.state.selectedShipmentMethod;
		_.each(this.props.contaktiChat.shipment_methods, (method) => {
			if (selectedId == method.id) {
				selected_method = method;
			}
		});
		await this.setState({
			selectedShipmentMethod: selected_method,
			selectedShipmentMethodPrice: selected_method.price,
		});
		this.calculateSum();
	};

	calculateSum = () => {
		let sum = 0;
		sum = this.state.priceWithoutTaxes + this.state.taxes + (parseFloat(this.state.selectedShipmentMethod.price) || 0 );
		this.setState( { sum } );
	}

	handleCheckoutMethodChange = (event) => {
		this.setState({ selectedCheckoutMethod: event.target.value });
	};


  handleCartOrder = ( customerId ) => {
    this.props.handleOrder(
			customerId,
			this.state.products,
			this.state.selectedCheckoutMethod,
			this.state.selectedShipmentMethod,
			this.state.priceWithoutTaxes,
			this.state.taxes,
			this.state.sum
		);
  }

  render() {
    let { products } = this.state;
    const { contaktiChat } = this.props
    let color = contaktiChat.color;
    let text_color = contaktiChat.text_color;
    const { translations } = contaktiChat;
    const cartTranslations = translations.user_dashboard.shopping_cart;

    return (
			<div id="contakti_cart_box" className="cart_box">
				<CustomerFormModal
					selectedCheckoutMethod={this.state.selectedCheckoutMethod}
					translations={cartTranslations}
					buttonColor={contaktiChat.color}
					handleShow={this.handleCustomerFormModalShow}
					handleClose={this.handleCustomerFormModalClose}
					handleCartOrder={this.handleCartOrder}
					show={this.state.showCustomerFormModal}
					origin={contaktiChat.origin}
					setPluginDisabledState={ this.setPluginDisabledState }
					orderTermsAndConditions={contaktiChat.orderTermsAndConditions}
				/>
				<div className="msg_head" style={{ backgroundColor: color }}>
					<span id="contakti-user-name" style={{ color: text_color }}>
						{" "}
						{cartTranslations.cart_title}
					</span>
					<span
						id="close-cart-icon"
						className="float-end p-1 mr-2 d-none d-sm-block d-md-none"
						onClick={this.props.toggleCart}
					>
						<i className="fa fa-times"></i>
					</span>
				</div>

				<div className="cart_body d-flex flex-column justify-content-between mh-75">
					<div className="mb-auto">
						<div className="overflow-scroll" style={{ maxHeight: "225px" }}>
							<Product
								products={products}
								onProductRemove={this.onProductRemove}
								increaseQuantity={this.addProduct}
								replaceProduct={this.replaceProduct}
								translations={cartTranslations}
								handleShow={this.props.handleShow}
								currency={this.state.currency}
							/>
						</div>
						<div>
							<table className="table table-condensed table-striped ">
								<tbody id="cart_body">
									<tr className="table-active">
										<td className="px-1 border-0 text-end" colSpan="3">
											<strong>
												{cartTranslations.price_without_taxes}:{" "}
												{`${ChatUtils.displayPrice(
													this.state.priceWithoutTaxes
												)}${this.state.currency}`}
											</strong>
										</td>
										<td className="px-1 border-0 " />
									</tr>
									<tr>
										<td className="px-1 border-0 text-end" colSpan="3">
											<strong>
												{cartTranslations.taxes}:{" "}
												{`${ChatUtils.displayPrice(this.state.taxes)}${
													this.state.currency
												}`}
											</strong>
										</td>
										<td className="px-1 border-0 " />
									</tr>
									<tr>
										<td className="px-1 border-0 text-end" colSpan="3">
											<strong>
												{cartTranslations.shipment_charges}:{" "}
												{`${ChatUtils.displayPrice(
													this.state.selectedShipmentMethod.price
												)}${this.state.currency}`}
											</strong>
										</td>
										<td className="px-1 border-0 " />
									</tr>
									<tr>
										<td className="px-1 border-0 text-end" colSpan="3">
											<strong>
												{cartTranslations.total}:{" "}
												{`${ChatUtils.displayPrice(this.state.sum)}${
													this.state.currency
												}`}
											</strong>
										</td>
										<td className="px-1 border-0 " />
									</tr>
								</tbody>
							</table>
						</div>
					</div>

					<div className="flex-end">
						<div className="row form-group">
							<div className="col-6">
								<label className="fw-bold" style={{ fontSize: "0.8rem" }}>
									{cartTranslations.checkout_method}
								</label>
								<div className="centera" id="checkout_method_select">
									<select
										className="form-control w-100 py-1"
										style={{ fontSize: "0.7rem" }}
										onChange={this.handleCheckoutMethodChange}
										value={this.state.selectedCheckoutMethod}
									>
										{contaktiChat.checkout_methods.map((method) => {
											return (
												<option value={method}>
													{translations.service_channels[method]}
												</option>
											);
										})}
									</select>
								</div>
							</div>

							<div className="col-6">
								<label className="fw-bold" style={{ fontSize: "0.8rem" }}>
									{translations.shipment_methods.title}
								</label>
								<div className="centera" id="shipment_method_select">
									<select
										className="form-control w-100 py-1"
										style={{ fontSize: "0.7rem" }}
										onChange={this.handleShipmentChange}
										value={this.state.selectedShipmentMethod.id}
									>
										{contaktiChat.shipment_methods.map((method, index) => {
											return (
												<option value={method.id} key={index}>
													{method.name}
												</option>
											);
										})}
									</select>
								</div>
							</div>
						</div>

						<div className="text-center">
							<button
								className="btn w-50"
								style={{
									color: text_color,
									backgroundColor: color,
								}}
								onClick={this.handleCustomerFormModalShow}
							>
								{cartTranslations.checkout}
							</button>
						</div>
					</div>
				</div>
			</div>
		);
  }
}

export default Cart;
