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
import './fluid/src/glslfluid';

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
    {value: 'stationary-top', label: 'Stationary (Top)'}
];

class Options extends React.Component {
    constructor(props) {
        super(props);
        this.state = {
            warmStarting: true, rk2Advection: false, jacobiDamping: 0.67, iterations: 10,
            method: 'pic', resolution: '128', timeStep: 0.03, substeps: 10, flipBlending: 0.8, particleSize: 2.5
        };
        window.settings = this.state;
    }

    handleChange(key, value) {
        this.setState({[key]: value}, ()=> {
            window.settings = this.state;
        });
    }

    render() {
        var onPause = ()=> {
            window.simulationPause();
        };
        var onReset = ()=> {
            window.resetFluid();
        };
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
                        <Button icon="pause" label="Pause" onClick={onPause}/>
                        <Button icon="undo" label="Reset" onClick={onReset}/>
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
                        <p style={{color: '#933'}}> Settings above will be applied after RESETTING. </p>
                        <br />
                        Visual Particle Size
                        <Slider min={1} max={15} step={0.1} value={this.state.particleSize} editable
                                onChange={this.handleChange.bind(this, 'particleSize')}/>
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
                        Jacobi Damping (Param. for the Damped Jacobi pressure solver)
                        <Slider min={0} max={2} value={this.state.jacobiDamping} editable
                                onChange={this.handleChange.bind(this, 'jacobiDamping')}/>
                        Frame Time Step
                        <Slider editable min={0.0001} max={0.1} step={0.0001} value={this.state.timeStep}
                                onChange={this.handleChange.bind(this, 'timeStep')}/>
                        Substeps (subdivisions of frame timestep)
                        <Slider snaps min={1} max={20} step={1} value={this.state.substeps} editable
                                onChange={this.handleChange.bind(this, 'substeps')}/>
                        FLIP Blending (smaller = more viscous)
                        <Slider min={0} max={1} step={0.01} value={this.state.flipBlending} editable
                                onChange={this.handleChange.bind(this, 'flipBlending')}/>
                    </CardText>
                </Card>
            </div>
            <div style={{margin: '0 auto', width: '1080px'}}>
                <Card style={{width: '1030px', float: 'left', margin: '0px 10px 10px 10px'}}>
                    <CardTitle title="Introduction"/>
                    <CardText>
                        This is an GPU-based fluid simulator. It gets access to the user's local GPU through WebGL.
                        Currently, several simulation methods are implemented: Marker & Cell(Eulerian), Particle in Cell (Hybrid), Fluid Implicit Particles (Hybrid).
                        The author wrote this project because he thinks it's interesting to play with water in his browser. Currently this project is just a prototype.
                    </CardText>
                    <CardText>
                        Pressure is solved by a damped Jacobi iterative solver instead of traditional ICCG.
                        Compared with ICCG, damped Jacobi is much more friendly to the legacy API and easier to implement.
                        Most importantly, it just works well so far.
                        A multi-grid pressure solver may be implemented in the future if necessary.
                        Note that if the Jacobi iterations are too few, the fluid will seem compressible.
                        "Warm Starting" means using the pressure for last step as the initial value for current step.
                        This significantly reduces the number of iterations required.
                    </CardText>
                    <CardText>
                        Currently there exists some known issues, such as the volume of the fluid slowly shrinks.
                        One remedy to this may be adding some adjustment to the pressure and reseeding the particles.
                        However, since WebGL doesn't support atomic operations,
                        adding reseeding tactics can be rather challenging. Many features will be added in the future, notwithstanding.
                    </CardText>
                    <CardText>
                        The code of this simulator is majorly written in CoffeeScript and GLSL. React.js is used for the user interface.
                        The author uses React-toolbox for components that obey Google's Material Design.
                    </CardText>
                    <CardText>
                        The source code will be hosted on github once the author thinks it is well organized and won't pollute the readers' eyes :-).
                        If you want to get the source code now anyway, or have some suggestions on this project, please contact the author (hu-ym13@mails.tsinghua.edu.cn).
                        Comments are appreciated! :->
                    </CardText>
                    <CardTitle
                        avatar={require("./me.png")}
                        title="Yuanming Hu"
                        subtitle="Feb. 2016"
                    />
                </Card>
            </div>
        </ToolboxApp>
    }
}
;

ReactDOM.render((
    <Options/>
), document.getElementById('app'));
