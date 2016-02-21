// You can also include here commons if you want with import 'react-toolbox/lib/commons';
import React from 'react';
import ReactDOM from 'react-dom';
import ToolboxApp from 'react-toolbox/lib/app';
import Button from 'react-toolbox/lib/button';
import Slider from 'react-toolbox/lib/slider';
import Dropdown from 'react-toolbox/lib/dropdown';
import {Card, CardTitle, CardText, CardActions, CardMedia} from 'react-toolbox/lib/card';
import FontIcon from 'react-toolbox/lib/font_icon';
import Switch from 'react-toolbox/lib/switch';
import Header from './components/header';
import Navigation from 'react-toolbox/lib/navigation';
import Link from 'react-toolbox/lib/link';
import style from './style';
import './fluid/src/glslfluid'

const resolutions = [
    {value: '16', label: '16x16'},
    {value: '32', label: '32x32'},
    {value: '64', label: '64x64'},
    {value: '128', label: '128x128'},
    {value: '256', label: '256x256'},
    {value: '512', label: '512x512'}
];

const methods = [
    {value: 'mac', label: 'Marker and Cell'},
    {value: 'pic', label: 'PIC/FLIP'}
];

const initialStates = [
    {value: 'dam-left', label: 'Dam Break (Left)'},
    {value: 'dam-middle', label: 'Dam Break (Middle)'},
    {value: 'dam-double', label: 'Dam Break (Double)'},
    {value: 'stationary-bottom', label: 'Stationary (Bottom)'},
    {value: 'stationary-top', label: 'Stationary (Top)'},
];

class Options extends React.Component {
    constructor(props) {
        super(props);
        this.state = {
            warmStarting: true, rk2Advection: false, jacobiDamping: 0.67, iterations: 10,
            method: 'pic', resolution: '128', timeStep: 0.01, substeps: 5, flipBlending: 0.95
        };
        window.settings = this.state;
    }

    handleChange(key, value) {
        this.setState({[key]: value});
        window.settings = this.state;
    }

    render() {
        return <ToolboxApp width={{width:'300px'}}>
            <Header />
            <div style={{margin: '0 auto', width: '1080px'}}>
                <Card style={{width: '512px', float: 'left', margin: '10px', height: '600px'}}>
                    <CardTitle title="Visualization"/>
                    <canvas id="main-canvas" width="512" height="512" style={{marginTop: 'auto'}}></canvas>
                </Card>
                <Card style={{width: '200px', float: 'left', margin: '10px 0px 0px 0px', height: '600px'}}>
                    <CardTitle title="Control"/>
                    <CardActions>
                        <Button icon="pause" label="Pause"/>
                        <Button icon="undo" label="Reset"/>
                    </CardActions>
                    <CardText>
                        Simulation Method
                        <Dropdown
                            auto
                            onChange={this.handleChange.bind(this, 'method')}
                            source={methods}
                            value={this.state.method}
                        />
                        Simulation Resolution
                        <Dropdown
                            auto
                            onChange={this.handleChange.bind(this, 'resolution')}
                            source={resolutions}
                            value={this.state.resolution}
                        />
                        Initial State
                        <Dropdown
                            auto
                            onChange={this.handleChange.bind(this, 'initialState')}
                            source={initialStates}
                            value={this.state.initialState}
                        />
                        <br />
                        <br />
                        <p style={{color: '#933'}}> Settings above will be applied after RESETTING. </p>
                    </CardText>
                </Card>
                <Card style={{width: '300px', float: 'left', margin: '10px', height: '600px'}}>
                    <CardTitle title="Parameters"/>
                    <CardText>
                        <Switch
                            checked={this.state.warmStarting}
                            label="Warm Starting"
                            onChange={this.handleChange.bind(this, 'warmStarting')}
                        />
                        <Switch
                            checked={this.state.rk2Advection}
                            label="RK2 Advection"
                            onChange={this.handleChange.bind(this, 'rk2Advection')}
                        />
                        Jacobi Iterations
                        <Slider snaps step={1} min={0} max={30} value={this.state.iterations} editable
                                onChange={this.handleChange.bind(this, 'iterations')}/>
                        Jacobi Damping
                        <Slider min={0} max={2} value={this.state.jacobiDamping} editable
                                onChange={this.handleChange.bind(this, 'jacobiDamping')}/>
                        Time Step
                        <Slider editable min={0.0001} max={0.1} step={0.0001} value={this.state.timeStep}
                                onChange={this.handleChange.bind(this, 'timeStep')}/>
                        Substeps
                        <Slider snaps min={1} max={20} step={1} value={this.state.substeps} editable
                                onChange={this.handleChange.bind(this, 'substeps')}/>
                        FLIP Blending
                        <Slider min={0} max={1} step={0.01} value={this.state.flipBlending} editable
                                onChange={this.handleChange.bind(this, 'flipBlending')}/>
                    </CardText>
                </Card>
            </div>
        </ToolboxApp>
    }
}
;

ReactDOM.render((
    <Options/>
), document.getElementById('app'));
