import React, { Component } from "react";
import { Button, Modal } from "react-bootstrap";
import Api from "../../classes/Api";
import TermsAndConditionsModal from "./TermsAndConditionsModal"
import "./CustomerFormModal.scss"

class CustomerFormModal extends Component {
	constructor(props) {
		super(props);
		this.state = {
			errors: {},
			disabledFormContent: false,
			agreedToTermsAndConditions: false,
			showTermsModal: false
		};
		this.customerFormInputs = [
			"full_name",
			"email",
			"phone_number",
			"street_address",
			"city",
			"zip_code",
		];
	}

	componentDidMount() {
		document.addEventListener("keydown", (e) => {
			if (e.key === "Escape") {
				e.preventDefault();
			}
		});
	}

	toggleAcceptTermsChecbox = (checked) => {
			this.setState( { agreedToTermsAndConditions: checked })
	}
		

	handleTermsModalClose = () => {
		this.setState({showTermsModal: false})
	}

	handleClose = () => {
		this.setState({ errors: {} });
		this.props.handleClose();
	};

	submitForm = () => {
		this.form.dispatchEvent(
			new Event("submit", { cancelable: true, bubbles: true })
		);
	};
	errors(key) {
		if (this.state.errors[key]) {
			return (
				<span
					className="w-100 text-end text-danger"
					style={{ fontSize: "0.75rem" }}
				>
					{`${this.props.translations.customer[key]} `}
					{this.state.errors[key].map((e) => {
						return e;
					})}
				</span>
			);
		}
	}

	setPluginDisabledState = (disabled) => {
		this.setState({ disabledFormContent: disabled });
		this.props.setPluginDisabledState(disabled);
	};

	handleSubmit = async (e) => {
		this.setState({
			errors: {},
		});
		e.preventDefault();
		this.setPluginDisabledState(true);
		let customerData = {};
		let form = e.target;
		customerData[ "customer" ] = {};
		customerData["customer"]["full_name"] = form.full_name.value;
		customerData["customer"]["email"] = form.email.value;
		customerData["customer"]["phone_number"] = form.phone_number.value;
		customerData["customer"]["street_address"] = form.street_address.value;
		customerData["customer"]["city"] = form.city.value;
		customerData["customer"]["zip_code"] = form.zip_code.value;

		const url = "customers";
		let createdCustomer = await new Api().post(url, customerData);
		if (createdCustomer && !createdCustomer.errors) {
			this.props.handleCartOrder(
				createdCustomer.id
			);
		} else if (createdCustomer.errors) {
			this.setState({
				errors: createdCustomer.errors,
			});
			this.setPluginDisabledState(false);
		} else {
			this.setPluginDisabledState(false);
		}
	};

	render() {
		const cartTranslations = this.props.translations;
		const customerTranslations = cartTranslations.customer;

		return (
			<>
				<TermsAndConditionsModal
					show={ this.state.showTermsModal }
					orderTermsAndConditions={ this.props.orderTermsAndConditions }
					handleTermsModalClose={ this.handleTermsModalClose }
					cartTranslations={ cartTranslations }
					acceptTerms={ () => this.toggleAcceptTermsChecbox( true ) }
					buttonColor={ this.props.buttonColor }
				/>
				<Modal
					show={this.props.show}
					onHide={this.handleClose}
					backdrop="static"
				>
					<div
						className={
							this.state.disabledFormContent == true ? "disabled-content" : ""
						}
					>
						<Modal.Header closeButton className="py-1">
							<Modal.Title>{customerTranslations.title}</Modal.Title>
						</Modal.Header>
						<Modal.Body>
							<form
								ref={(f) => {
									this.form = f;
								}}
								onSubmit={(e) => {
									this.handleSubmit(e);
								}}
								className="form-group mb-1 customer-details-form"
							>
								{this.customerFormInputs.map((field_name) => {
									return (
										<>
											<div className="d-flex w-100 justify-content-between">
												<label className="w-100 my-1">
													<span
														className="fw-bold"
													>
														{customerTranslations[field_name]}
													</span>
													<span className="pull-right">{this.errors(field_name)}</span>
												</label>
											</div>
											<input
												type="text"
												required
												className="form-control py-1"
												name={field_name}
											/>
										</>
									);
								})}
							
								<div>
									<input
										className="form-check-input me-1"
										type="checkbox"
										checked={ this.state.agreedToTermsAndConditions }
										defaultChecked={ this.state.agreedToTermsAndConditions }
										onChange={ (e) => this.toggleAcceptTermsChecbox(e.target.checked) } 
										required>
									</input>
									<label>
										<a
											className="ms-1"
											onClick={()=>{this.setState({showTermsModal: true})}}
										>{this.props.orderTermsAndConditions.subject}</a>
									</label>
								</div>
							</form>
				
						</Modal.Body>
						<Modal.Footer className="py-1">
							<Button
								className={this.state.agreedToTermsAndConditions ? "" : "disabled"}
								variant="secondary"
								style={{ background: this.props.buttonColor }}
								size="sm"
								onClick={this.submitForm}
							>
								{this.props.selectedCheckoutMethod == "checkout_paytrail"
									? cartTranslations.checkout_button_paytrail
									: cartTranslations.checkout_button_ticket}
							</Button>
						</Modal.Footer>
					</div>
				</Modal>
			</>
		);
	}
}

export default CustomerFormModal;
