import React, { Component } from 'react';
import { Carousel } from 'react-bootstrap';
class CarouselWrapper extends Component {
    constructor(props) {
        super(props);
        this.state = { index: 0}
    }
    componentDidMount(){
        let activeIndex = this.props.activeIndex ;
        this.setState({ index: activeIndex});
    }
    handleSelect= (selectedIndex, e) => {
        this.setState({ index: selectedIndex  });
    }
    render() { 
        
        return ( <> 
        <Carousel activeIndex={this.state.index} onSelect={this.handleSelect}>
            {this.props.images.map((image, index) => {
                return (
                    <Carousel.Item>
                        <img
                            className="d-block w-100"
                            src={`${this.props.origin}${image.file.url}`}
                            alt={image.file_name}
                        />
                    </Carousel.Item>
                )
            })}

        </Carousel></> );
    }
}
 
export default CarouselWrapper;