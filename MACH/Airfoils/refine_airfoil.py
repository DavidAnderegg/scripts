import os
import numpy as np
import matplotlib.pyplot as plt
from scipy import interpolate

# This script takes an airfoil file and refines it to a cos-distribution with
# the help of a spline interpolation

input_file = 'base_unitized.dat'
plot_final = True

n_upper = 130       # number of point on top
n_lower = 130       # number of point on bottom
order = 3           # order of spline interpolation

inp_split = os.path.splitext(input_file)
output_file = inp_split[0] + '_refined' + inp_split[1]


# ###########################################
# Non-User stuff
# ###########################################
def get_spline(airfoil, order):
    airfoil = np.transpose(airfoil)
    # print(airfoil[0])
    x = airfoil[0]
    y = airfoil[1]
    tck = interpolate.splrep(
        x, y, k=order)  # type:ignore

    return tck


def get_coords(tck, x):
    y = interpolate.splev(x, tck)

    # return np.transpose(np.array([x, y]))
    return np.transpose(np.array([x, y]))


# read airfoil
airfoil_raw = np.loadtxt(input_file)

# split airfoil in upper and lower
i_LE = np.argmin(airfoil_raw[:, 0])  # type:ignore
upper_raw = airfoil_raw[:i_LE + 1]
lower_raw = airfoil_raw[i_LE:]

# refine upper
x = (np.array(1) - np.cos(np.linspace(np.pi, 0, n_upper + 1))) / np.array(2)
upper_raw = np.flip(upper_raw, axis=0)
tck = get_spline(upper_raw, order)
upper = get_coords(tck, x)

# refine lower
x = (np.array(1) - np.cos(np.linspace(0, np.pi, n_lower + 1))) / np.array(2)
tck = get_spline(lower_raw, order)
lower = get_coords(tck, x)

# stich everything together
airfoil = np.concatenate((upper[:-1], [[0, 0]], lower[1:]))

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
