import React, { Component } from 'react';
import { Button, Modal, } from 'react-bootstrap'
import CarouselWrapper from '../modules/utils/CarouselWrapper';
class MessageImagesModal extends Component {
    constructor(props) {
        super(props);
        this.state = {}
    }

    handleClose = () => {
        this.props.handleClose()
    }
    render() {
        return (
            <>
                <Modal show={this.props.showModal} onHide={this.handleClose}>
                    <Modal.Body>
                        <CarouselWrapper
                            images={this.props.images}
                            origin={this.props.origin}
                            activeIndex={this.props.activeIndex}
                        />
                    </Modal.Body>
                </Modal>
            </>
        );
    }
}

export default MessageImagesModal;