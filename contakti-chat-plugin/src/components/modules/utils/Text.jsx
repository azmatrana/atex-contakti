import parse from 'html-react-parser';

const Text = (props) => {
    return parse(props.text)
}
 
export default Text;