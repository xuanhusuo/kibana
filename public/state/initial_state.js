import { get } from 'lodash';

export default (path) => {
  const state = {
    app: {}, // Kibana stuff in here
    throwAway: {
      expression: 'demodata().pointseries(x=time, y=.math("sum(cost)")).line()',
      renderable: null,
    },
    transient: {},
    persistent: {},
  };

  if (!path) {
    return state;
  }

  return get(state, path);
};
