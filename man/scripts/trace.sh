"${KAPPABIN}"KaSa ../kappa/protein2x2.ka --compute-local-traces --no-output-directory && \
    dot -Tpng Agent_trace_P_a1~_a2~_b1~_b2~_g\!.dot -o ../generated_img/trace_raw.png && \
    rm *.dot && \
    "${KAPPABIN}"KaSa ../kappa/protein2x2.ka --compute-local-traces --no-output-directory --use-macrotransitions-in-local-traces && \
    dot -Tpng Agent_trace_P_a1~_a2~_b1~_b2~_g\!.dot -o ../generated_img/trace_macro.png && \
    rm *.dot

