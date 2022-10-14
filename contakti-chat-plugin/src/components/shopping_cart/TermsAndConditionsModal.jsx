import React, { Component } from "react";
import { Button, Modal } from "react-bootstrap";
import Text from '../modules/utils/Text'

class TermsAndConditionsModal extends Component {
	constructor(props) {
		super(props);
    this.state = {};
	}

	componentDidMount() {
		document.addEventListener("keydown", (e) => {
			if (e.key === "Escape") {
				e.preventDefault();
			}
		});
	}

	render() {

		return (
			<>
        <Modal
          id="termsModal"
					show={this.props.show}
          backdrop="static"
          onHide={this.props.handleTermsModalClose}
        >
          <Modal.Header closeButton className="py-1">
            <Modal.Title>{this.props.cartTranslations.terms_modal_heading}</Modal.Title>
          </Modal.Header>
          <Modal.Body>
            <div className="border p-3">
              <Text text={ this.props.orderTermsAndConditions.body }></Text>
            </div>
          </Modal.Body>
          <Modal.Footer>
            <Button
              onClick={ () => {
                this.props.acceptTerms();
                this.props.handleTermsModalClose();
              }
              }
              variant="secondary"
              style={{ background: this.props.buttonColor }}
            >{ this.props.cartTranslations.accept }</Button>
          </Modal.Footer>
				</Modal>
			</>
		);
	}
}

export default TermsAndConditionsModal;
