import numpy as np
from scipy.spatial import distance
import math as m
import os
import matplotlib.pyplot as plt


# This script takes an airfoil file and saves it in "unitized" form where the
# chord equals 1 and the X-Axis lines up with LE and TE.

input_file = 'flap.dat'
plot_final = True

inp_split = os.path.splitext(input_file)
output_file = inp_split[0] + '_unitized' + inp_split[1]


# ###########################################
# Non-User stuff
# ###########################################
def find_TE(airfoil):
    # TE is just the center between the first and the last point of the
    # coordinates
    x = (airfoil[0, 0] + airfoil[-1, 0]) / 2
    y = (airfoil[0, 1] + airfoil[-1, 1]) / 2

    return np.array([x, y])


def find_LE(airfoil, TE=np.array([[1, 0]])):
    # The LE is the point which is the furthest away from TE (1, 0)

    # calculate distances
    dist = distance.cdist(airfoil, [TE])

    # find biggest distance -> TE
    i_TE = np.argmax(dist)
    return airfoil[i_TE]


def unitize(airfoil, LE=np.array([[0, 0]]), TE=np.array([[1, 0]])):
    # This moves the LE to (0, 0) and the TE to (1, 0)

    # move LE to 0, 0
    airfoil = airfoil-LE
    TE = TE-LE

    # rotate airfoil so chord lies on x-axis
    # first, find angle
    u1 = np.array([1, 0])
    u2 = TE / np.linalg.norm(TE)
    theta = m.acos(np.abs(np.dot(u1, u2)))
    if TE[1] < 0:
        theta = - theta

    # # rotate the airfoil
    R = np.array([[m.cos(theta), -m.sin(theta)], [m.sin(theta), m.cos(theta)]])
    airfoil = np.dot(airfoil, R)

    # scale airfoil
    s = 1 / TE[0]
    airfoil *= s

    return airfoil


# read airfoil
airfoil_raw = np.loadtxt(input_file)


TE = find_TE(airfoil_raw)
LE = find_LE(airfoil_raw, TE)
airfoil = unitize(airfoil_raw, LE, TE)

# save airfoil
np.savetxt(output_file, airfoil)


# plot airfoil
if plot_final:
    plt.plot(airfoil[:, 0], airfoil[:, 1], '-+', label='final')
    plt.plot(airfoil_raw[:, 0], airfoil_raw[:, 1], ':r', label='original')
    plt.title(input_file)
    plt.grid()
    plt.legend()
    plt.axis('equal')
    plt.show()
