# Ember.js + RPi

## Introduction / background

This presentation came about because I (jacobq) had recently been tasked by my employer to add a simple, flexible web interface to one of our products. Although this instrument had a [PLC](https://en.wikipedia.org/wiki/Programmable_logic_controller) that included an Ethernet [NIC](https://en.wikipedia.org/wiki/Network_interface_controller), it was quite limited in its capabilities. We don't currently produce enough of these units per year to justify designing custom electronics just for this, so I decided to try integrating a [Raspberry Pi](https://www.raspberrypi.org/) (RPi) [SBC](https://en.wikipedia.org/wiki/Single-board_computer). I used [nginx](https://nginx.org/) to serve a static [ember.js](https://emberjs.com/) app and map requests for URLs matching `/ws` to a [node.js](https://nodejs.org/en/) back-end using [WebSocket](https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API)s and was pleased with the results. Having learned a lot along the way I thought that I ought to share about the experience.

It should be noted that the design choices in this example are not the only--or even the best--ones. Different applications will benefit from different choices. Hopefully, however, what I've provided here is sufficiently modular that others can adapt it to their needs.


## File structure

(*TODO*: add files / submodules for these)

* [`back-end/`](./back-end/) Source code for Node.js back-end
* [`front-end/`](./front-end/) Source code for Ember.js front-end
* [`rpi/`](./rpi) Content related to setup of the RPi
* [`slides/`](./slides/) Presentation (made with [reveal.js](https://github.com/hakimel/reveal.js))
