import React, { Component } from 'react';
import { Button, Modal, } from 'react-bootstrap'
import CarouselWrapper from '../modules/utils/CarouselWrapper';
import ChatUtils from '../../classes/ChatUtils';

class ProductInfoModal extends Component {
    constructor(props) {
        super(props);
        this.state = {
            show: false,

        }
    }
    handleClose = () => {
        this.props.handleClose();
    }
    render() {
        let { product, currency, translations } = this.props;
        return (
            <>
                <Modal show={this.props.show} onHide={this.handleClose}>
                    <Modal.Header closeButton>
                        <Modal.Title>{translations.title}</Modal.Title>
                    </Modal.Header>
                    <Modal.Body>
                        <div className="d-flex justify-content-between px-2">
                            <span className="float-start">{product.title}</span>
                            <span className="float-end">
                                <span>{ translations.price }:{ ' ' }</span><span>{ ChatUtils.displayPrice( product.price ) }{ currency }{' '}</span>
                                {
                                    // <span>{` ${product.with_vat ? translations.including : translations.excluding } `}</span>
                                    // <span>{ ` ${ product.vat?.vat_percentage || 0 }% ${ translations.vat }` }</span>
                                }
                            </span>
                        </div>
                        <hr />
                        {product.images && product.images.length > 0 &&
                            <div>
                                <CarouselWrapper 
                                images={product.images}
                                origin={this.props.origin}
                                 />    
                                <hr />
                            </div>
                        }

                        <div  className="overflow-auto mt-1 px-2" >
                            <div>{product.description}</div>
                            {product.attachments && product.attachments.length > 0 && <div>
                                {product.attachments.map((f, index) => {
                                    return (
                                        <span className="mx-1">
                                            <a className="text-decoration-none" href={`${this.props.origin}${f.file.url}`} download >{f.file_name}</a>
                                        </span>
                                    )
                                })}
                            </div>
                            }

                        </div>
                    </Modal.Body>
                    <Modal.Footer>
                        <Button variant="secondary" style={{ background: this.props.buttonColor }}  size="sm" onClick={this.handleClose}>
                            {translations.close}
                        </Button>
                    </Modal.Footer>
                </Modal>
            </>
        )
    }
}

export default ProductInfoModal;
