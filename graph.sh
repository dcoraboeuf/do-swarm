#!/bin/bash

terraform graph | dot -Tpng > graph.png
